import Foundation
import Testing
@testable import KeepAwake

final class ShellRecorder: @unchecked Sendable {
    var commands: [String] = []
    var status: Int32 = 0
}

struct AgentInstallerTests {
    private let home = FileManager.default.temporaryDirectory
        .appendingPathComponent("keepAwakeHome-\(UUID().uuidString)", isDirectory: true)
    private let shell = ShellRecorder()
    private let exe = "/Applications/keepAwake.app/Contents/MacOS/KeepAwake"
    private var ourCommand: String { "\"\(exe)\" hook --pid $PPID" }

    private var claudeSettings: URL { home.appendingPathComponent(".claude/settings.json") }
    private var cursorHooks: URL { home.appendingPathComponent(".cursor/hooks.json") }
    private var cursorMCP: URL { home.appendingPathComponent(".cursor/mcp.json") }

    private func installer(executable: String? = nil) -> AgentInstaller {
        let shell = shell
        return AgentInstaller(home: home, executable: executable ?? exe) { command in
            shell.commands.append(command)
            return (shell.status, "")
        }
    }

    private func write(_ text: String, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(text.utf8).write(to: url)
    }

    private func json(_ url: URL) throws -> [String: Any] {
        try #require(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
    }

    /// All hook commands registered for one Claude Code event.
    private func claudeCommands(_ event: String) throws -> [String] {
        let hooks = try json(claudeSettings)["hooks"] as? [String: Any]
        let groups = hooks?[event] as? [[String: Any]] ?? []
        return groups.flatMap { ($0["hooks"] as? [[String: Any]] ?? []).compactMap { $0["command"] as? String } }
    }

    private func cursorCommands(_ event: String) throws -> [String] {
        let hooks = try json(cursorHooks)["hooks"] as? [String: Any]
        return (hooks?[event] as? [[String: Any]] ?? []).compactMap { $0["command"] as? String }
    }

    private let claudeEvents = ["UserPromptSubmit", "PostToolUse", "Stop", "SessionEnd"]
    private let cursorEvents = ["beforeSubmitPrompt", "postToolUse", "stop", "sessionEnd"]

    @Test func claudeInstallPreservesOtherSettings() throws {
        try write(#"{"model":"opus","hooks":{"Stop":[{"hooks":[{"type":"command","command":"say done"}]}]}}"#, to: claudeSettings)
        _ = try installer().install(.claudeCode)
        #expect(try json(claudeSettings)["model"] as? String == "opus")
        #expect(try claudeCommands("Stop") == ["say done", ourCommand])
        for event in claudeEvents {
            #expect(try claudeCommands(event).filter { $0 == ourCommand }.count == 1)
        }
        let groups = try json(claudeSettings)["hooks"] as? [String: Any]
        #expect(((groups?["PostToolUse"] as? [[String: Any]])?.first?["matcher"] as? String) == "*")
        #expect(shell.commands.last?.contains("claude mcp add --scope user keepawake -- '\(exe)' mcp") == true)
        #expect(installer().isInstalled(.claudeCode))
    }

    @Test func installTwiceIsIdempotent() throws {
        for target in AgentTarget.allCases {
            _ = try installer().install(target)
            _ = try installer().install(target)
        }
        for event in claudeEvents { #expect(try claudeCommands(event) == [ourCommand]) }
        for event in cursorEvents { #expect(try cursorCommands(event) == [ourCommand]) }
    }

    @Test func movedAppReplacesOldEntry() throws {
        _ = try installer(executable: "/Old/keepAwake.app/Contents/MacOS/KeepAwake").install(.claudeCode)
        _ = try installer().install(.claudeCode)
        #expect(try claudeCommands("UserPromptSubmit") == [ourCommand])
    }

    @Test func malformedJsonUntouched() throws {
        try write("{oops", to: claudeSettings)
        #expect(throws: InstallerError.unreadable(path: claudeSettings.path)) {
            try installer().install(.claudeCode)
        }
        #expect(String(decoding: try Data(contentsOf: claudeSettings), as: UTF8.self) == "{oops")
    }

    @Test func cursorInstallWritesHooksAndMcp() throws {
        try write(#"{"mcpServers":{"other":{"command":"x"}}}"#, to: cursorMCP)
        _ = try installer().install(.cursor)
        #expect(try json(cursorHooks)["version"] as? Int == 1)
        for event in cursorEvents { #expect(try cursorCommands(event) == [ourCommand]) }
        let servers = try json(cursorMCP)["mcpServers"] as? [String: Any]
        let ours = servers?["keepawake"] as? [String: Any]
        #expect(ours?["command"] as? String == exe)
        #expect(ours?["args"] as? [String] == ["mcp"])
        #expect(servers?["other"] != nil)
        #expect(installer().isInstalled(.cursor))
    }

    @Test func uninstallRemovesOnlyOurs() throws {
        try write(#"{"hooks":{"Stop":[{"hooks":[{"type":"command","command":"say done"}]}]}}"#, to: claudeSettings)
        try write(#"{"version":1,"hooks":{"stop":[{"command":"./mine.sh"}]}}"#, to: cursorHooks)
        try write(#"{"mcpServers":{"other":{"command":"x"}}}"#, to: cursorMCP)
        for target in AgentTarget.allCases {
            _ = try installer().install(target)
            _ = try installer().uninstall(target)
        }
        #expect(try claudeCommands("Stop") == ["say done"])
        #expect(try claudeCommands("UserPromptSubmit").isEmpty)
        #expect(try cursorCommands("stop") == ["./mine.sh"])
        #expect(try cursorCommands("beforeSubmitPrompt").isEmpty)
        let servers = try json(cursorMCP)["mcpServers"] as? [String: Any]
        #expect(servers?["keepawake"] == nil)
        #expect(servers?["other"] != nil)
        #expect(shell.commands.last?.contains("claude mcp remove --scope user keepawake") == true)
        #expect(!installer().isInstalled(.claudeCode))
        #expect(!installer().isInstalled(.cursor))
    }

    @Test func claudeMcpFallbackWhenCliMissing() throws {
        shell.status = 127
        let lines = try installer().install(.claudeCode)
        #expect(lines.joined(separator: "\n").contains("claude mcp add --scope user keepawake -- '\(exe)' mcp"))
    }

    @Test func backupWrittenOnce() throws {
        let original = #"{"model":"opus"}"#
        try write(original, to: claudeSettings)
        _ = try installer().install(.claudeCode)
        _ = try installer().install(.claudeCode)
        let backup = claudeSettings.appendingPathExtension("keepawake-backup")
        #expect(String(decoding: try Data(contentsOf: backup), as: UTF8.self) == original)
    }

    @Test func missingFilesAreCreated() throws {
        _ = try installer().install(.cursor)
        #expect(FileManager.default.fileExists(atPath: cursorHooks.path))
        #expect(!FileManager.default.fileExists(atPath: cursorHooks.appendingPathExtension("keepawake-backup").path))
    }

    @Test func cliInstallRejectsUnknownTarget() {
        var err: [String] = []
        let status = AgentInstaller.runCLI(["install", "vim"], installer: installer(), out: { _ in }, err: { err.append($0) })
        #expect(status == 64)
    }
}
