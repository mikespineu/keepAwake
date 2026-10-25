import Foundation
import Testing
@testable import KeepAwake

struct AgentHookTests {
    private func response(_ json: String, pid: Int32? = 4242) -> (command: AgentCommand?, stdout: String) {
        AgentHook.response(for: Data(json.utf8), parentPID: pid)
    }

    private let claudeHold = AgentCommand.hold(HoldRequest(id: "claude-code:abc-123", name: "Claude Code", minutes: 30, pid: 4242))
    private let cursorHold = AgentCommand.hold(HoldRequest(id: "cursor:c1", name: "Cursor", minutes: 30, pid: 4242))

    @Test func claudePromptHolds() {
        let result = response(#"{"hook_event_name":"UserPromptSubmit","session_id":"abc-123","prompt":"secret"}"#)
        #expect(result.command == claudeHold)
        #expect(result.stdout == "")
    }

    @Test func claudeToolUseRenews() {
        let result = response(#"{"hook_event_name":"PostToolUse","session_id":"abc-123","tool_input":{"command":"ls"}}"#)
        #expect(result.command == claudeHold)
        #expect(result.stdout == "")
    }

    @Test(arguments: ["Stop", "SessionEnd"])
    func claudeEndReleases(_ event: String) {
        let result = response(#"{"hook_event_name":"\#(event)","session_id":"abc-123"}"#)
        #expect(result.command == .release(id: "claude-code:abc-123"))
        #expect(result.stdout == "")
    }

    @Test func cursorPromptHoldsAndContinues() {
        let result = response(#"{"hook_event_name":"beforeSubmitPrompt","conversation_id":"c1","cursor_version":"2.0"}"#)
        #expect(result.command == cursorHold)
        #expect(result.stdout == #"{"continue":true}"#)
    }

    @Test func cursorToolUseRenews() {
        let result = response(#"{"hook_event_name":"postToolUse","conversation_id":"c1","cursor_version":"2.0"}"#)
        #expect(result.command == cursorHold)
        #expect(result.stdout == "")
    }

    @Test func cursorStopReleases() {
        let result = response(#"{"hook_event_name":"stop","conversation_id":"c1","cursor_version":"2.0"}"#)
        #expect(result.command == .release(id: "cursor:c1"))
        #expect(result.stdout == "{}")
    }

    @Test func cursorSessionEndReleases() {
        let result = response(#"{"hook_event_name":"sessionEnd","conversation_id":"c1","cursor_version":"2.0"}"#)
        #expect(result.command == .release(id: "cursor:c1"))
        #expect(result.stdout == "")
    }

    @Test func cursorPromptWithoutIdStillContinues() {
        let result = response(#"{"hook_event_name":"beforeSubmitPrompt","cursor_version":"2.0"}"#)
        #expect(result.command == nil)
        #expect(result.stdout == #"{"continue":true}"#)
    }

    @Test func badSessionIdIgnored() {
        #expect(response(#"{"hook_event_name":"Stop","session_id":"a b/c"}"#).command == nil)
    }

    @Test func unknownEventIgnored() {
        let result = response(#"{"hook_event_name":"PreCompact","session_id":"abc"}"#)
        #expect(result.command == nil)
        #expect(result.stdout == "")
    }

    @Test func garbageInput() {
        let result = response("not json")
        #expect(result.command == nil)
        #expect(result.stdout == "")
    }

    @Test func missingParentPidHoldsWithoutPid() {
        let result = response(#"{"hook_event_name":"UserPromptSubmit","session_id":"abc-123"}"#, pid: nil)
        #expect(result.command == .hold(HoldRequest(id: "claude-code:abc-123", name: "Claude Code", minutes: 30, pid: nil)))
    }

    @Test func parsesPidArgument() {
        #expect(AgentHook.parentPID(from: ["hook", "--pid", "4242"]) == 4242)
        #expect(AgentHook.parentPID(from: ["hook", "--pid", "$PPID"]) == nil)
        #expect(AgentHook.parentPID(from: ["hook"]) == nil)
    }

    @Test func hookExitsZeroWhenAppMissing() throws {
        let app = FakeApp()
        app.opens = false
        let pipe = Pipe()
        pipe.fileHandleForWriting.write(Data(#"{"hook_event_name":"Stop","session_id":"abc"}"#.utf8))
        try pipe.fileHandleForWriting.close()
        var printed: [String] = []
        let started = Date()
        let status = AgentHook.run(args: ["hook"], stdin: pipe.fileHandleForReading, client: app.client) { printed.append($0) }
        #expect(status == 0)
        #expect(Date().timeIntervalSince(started) < 0.5)
        #expect(printed.isEmpty)
    }
}
