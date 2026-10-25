import Foundation

/// `KeepAwake hook --pid $PPID`, run by Claude Code and Cursor hooks.
/// Holds the Mac awake while the agent works and lets it sleep when it finishes.
enum AgentHook {
    static let holdMinutes = 30

    /// Only these fields are decoded. Prompts and tool input are never read.
    private struct Input: Decodable {
        var hook_event_name: String?
        var session_id: String?
        var conversation_id: String?
        var cursor_version: String?
    }

    private enum Action { case hold, release }

    static func response(for input: Data, parentPID: Int32?) -> (command: AgentCommand?, stdout: String) {
        guard let input = try? JSONDecoder().decode(Input.self, from: input),
              let event = input.hook_event_name
        else { return (nil, "") }

        let isCursor = input.cursor_version != nil
        let action: Action?
        let stdout: String
        if isCursor {
            switch event {
            // Cursor waits for this answer before it sends the prompt.
            case "beforeSubmitPrompt": (action, stdout) = (.hold, #"{"continue":true}"#)
            case "postToolUse": (action, stdout) = (.hold, "")
            case "stop": (action, stdout) = (.release, "{}")
            case "sessionEnd": (action, stdout) = (.release, "")
            default: (action, stdout) = (nil, "")
            }
        } else {
            // Claude Code adds UserPromptSubmit output to the conversation, so it stays empty.
            stdout = ""
            switch event {
            case "UserPromptSubmit", "PostToolUse": action = .hold
            case "Stop", "SessionEnd": action = .release
            default: action = nil
            }
        }

        let session = isCursor ? input.conversation_id : input.session_id
        guard let action, let session else { return (nil, stdout) }
        let id = (isCursor ? "cursor:" : "claude-code:") + session
        let command: AgentCommand = switch action {
        case .hold: .hold(HoldRequest(id: id, name: isCursor ? "Cursor" : "Claude Code", minutes: holdMinutes, pid: parentPID))
        case .release: .release(id: id)
        }
        // Round-trip through the URL so the id rules apply here too.
        return (AgentCommand(url: command.url) == command ? command : nil, stdout)
    }

    static func parentPID(from args: [String]) -> Int32? {
        guard let index = args.firstIndex(of: "--pid"), index + 1 < args.count else { return nil }
        return Int32(args[index + 1])
    }

    /// Never blocks the agent: always exits 0 and never waits for the app to answer.
    static func run(
        args: [String],
        stdin: FileHandle,
        client: AgentClient,
        out: (String) -> Void
    ) -> Int32 {
        let input = (try? stdin.readToEnd()) ?? Data()
        // A pid that is already gone would end the hold at once; the TTL still ends it.
        let pid = parentPID(from: args).flatMap { client.isAlive($0) ? $0 : nil }
        let (command, stdout) = response(for: input, parentPID: pid)
        if let command { _ = client.send(command) }
        if !stdout.isEmpty { out(stdout) }
        return 0
    }
}
