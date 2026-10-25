import Foundation

enum AgentTarget: String, CaseIterable, Sendable {
    case claudeCode = "claude-code"
    case cursor

    var displayName: String {
        switch self {
        case .claudeCode: "Claude Code"
        case .cursor: "Cursor"
        }
    }
}

enum InstallerError: Error, Equatable, LocalizedError {
    /// The file exists but is not a JSON object; it is left as it is.
    case unreadable(path: String)

    var errorDescription: String? {
        switch self {
        case .unreadable(let path): "\(path) is not valid JSON, so it was left unchanged."
        }
    }
}

/// Adds keepAwake's hooks and MCP server to Claude Code and Cursor, and takes them out again.
/// Other settings and hooks in those files are kept as they are.
struct AgentInstaller: Sendable {
    var home: URL
    var executable: String
    var runShell: @Sendable (String) -> (status: Int32, output: String)

    init(
        home: URL = FileManager.default.homeDirectoryForCurrentUser,
        executable: String = Bundle.main.executablePath ?? "",
        runShell: @escaping @Sendable (String) -> (status: Int32, output: String) = AgentInstaller.loginShell
    ) {
        self.home = home
        self.executable = executable
        self.runShell = runShell
    }

    /// The App Store build can't write outside its container.
    static var isSandboxed: Bool { ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] != nil }

    private static let claudeEvents: [(name: String, matcher: String?)] = [
        ("UserPromptSubmit", nil), ("PostToolUse", "*"), ("Stop", nil), ("SessionEnd", nil),
    ]
    private static let cursorEvents = ["beforeSubmitPrompt", "postToolUse", "stop", "sessionEnd"]
    private static let ourSuffix = "/KeepAwake\" hook --pid $PPID"
    private static let mcpName = "keepawake"

    private var hookCommand: String { "\"\(executable)\" hook --pid $PPID" }
    private var claudeSettings: URL { home.appendingPathComponent(".claude/settings.json") }
    private var cursorHooks: URL { home.appendingPathComponent(".cursor/hooks.json") }
    private var cursorMCP: URL { home.appendingPathComponent(".cursor/mcp.json") }
    private var claudeMCPAdd: String { "claude mcp add --scope user \(Self.mcpName) -- '\(executable)' mcp" }

    private static func isOurs(_ handler: Any) -> Bool {
        ((handler as? [String: Any])?["command"] as? String)?.hasSuffix(ourSuffix) == true
    }

    // MARK: - Install

    func install(_ target: AgentTarget) throws -> [String] {
        switch target {
        case .claudeCode:
            try updateClaudeHooks(install: true)
            return ["Added keepAwake hooks to \(claudeSettings.path)", registerClaudeMCP()]
        case .cursor:
            try updateCursorHooks(install: true)
            try updateCursorMCP(install: true)
            return ["Added keepAwake hooks to \(cursorHooks.path)", "Added the keepawake MCP server to \(cursorMCP.path)"]
        }
    }

    func uninstall(_ target: AgentTarget) throws -> [String] {
        switch target {
        case .claudeCode:
            try updateClaudeHooks(install: false)
            _ = runShell("claude mcp remove --scope user \(Self.mcpName)")
            return ["Removed keepAwake hooks from \(claudeSettings.path)", "Removed the keepawake MCP server from Claude Code"]
        case .cursor:
            try updateCursorHooks(install: false)
            try updateCursorMCP(install: false)
            return ["Removed keepAwake hooks and MCP server from Cursor"]
        }
    }

    func isInstalled(_ target: AgentTarget) -> Bool {
        switch target {
        case .claudeCode:
            let groups = ((try? load(claudeSettings))??["hooks"] as? [String: Any])?[Self.claudeEvents[0].name] as? [[String: Any]]
            return groups?.contains { ($0["hooks"] as? [Any] ?? []).contains(where: Self.isOurs) } == true
        case .cursor:
            let handlers = ((try? load(cursorHooks))??["hooks"] as? [String: Any])?[Self.cursorEvents[0]] as? [Any]
            return handlers?.contains(where: Self.isOurs) == true
        }
    }

    // MARK: - Claude Code

    private func updateClaudeHooks(install: Bool) throws {
        let url = claudeSettings
        let original = try load(url)
        guard install || original != nil else { return }
        var settings = original ?? [:]
        var hooks = try object(settings["hooks"], in: url)
        let handler: [String: Any] = ["type": "command", "command": hookCommand, "timeout": 5]

        for event in Self.claudeEvents {
            var groups: [[String: Any]] = []
            for group in hooks[event.name] as? [[String: Any]] ?? [] {
                let handlers = group["hooks"] as? [Any] ?? []
                let kept = handlers.filter { !Self.isOurs($0) }
                // Only groups we emptied are dropped; anything else stays as it was.
                if kept.isEmpty && !handlers.isEmpty { continue }
                var group = group
                if group["hooks"] != nil { group["hooks"] = kept }
                groups.append(group)
            }
            if install {
                var group: [String: Any] = ["hooks": [handler]]
                if let matcher = event.matcher { group["matcher"] = matcher }
                groups.append(group)
            }
            hooks[event.name] = groups.isEmpty ? nil : groups
        }
        settings["hooks"] = hooks.isEmpty ? nil : hooks
        try save(settings, to: url, replacing: original != nil)
    }

    private func registerClaudeMCP() -> String {
        let manual = "Run this yourself to add the MCP server: \(claudeMCPAdd)"
        guard !executable.contains("'") else { return manual }
        let result = runShell("claude mcp remove --scope user \(Self.mcpName) >/dev/null 2>&1; \(claudeMCPAdd)")
        return result.status == 0 ? "Added the keepawake MCP server to Claude Code" : manual
    }

    // MARK: - Cursor

    private func updateCursorHooks(install: Bool) throws {
        let url = cursorHooks
        let original = try load(url)
        guard install || original != nil else { return }
        var file = original ?? [:]
        var hooks = try object(file["hooks"], in: url)
        let handler: [String: Any] = ["command": hookCommand, "timeout": 5]

        for event in Self.cursorEvents {
            var handlers = (hooks[event] as? [Any] ?? []).filter { !Self.isOurs($0) }
            if install { handlers.append(handler) }
            hooks[event] = handlers.isEmpty ? nil : handlers
        }
        file["version"] = file["version"] ?? 1
        file["hooks"] = hooks
        try save(file, to: url, replacing: original != nil)
    }

    private func updateCursorMCP(install: Bool) throws {
        let url = cursorMCP
        let original = try load(url)
        guard install || original != nil else { return }
        var file = original ?? [:]
        var servers = try object(file["mcpServers"], in: url)
        servers[Self.mcpName] = install ? ["command": executable, "args": ["mcp"]] : nil
        file["mcpServers"] = servers
        try save(file, to: url, replacing: original != nil)
    }

    // MARK: - Files

    /// nil when the file doesn't exist yet. An empty file counts as `{}`.
    private func load(_ url: URL) throws -> [String: Any]? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        if String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return [:] }
        guard let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            throw InstallerError.unreadable(path: url.path)
        }
        return object
    }

    private func object(_ value: Any?, in url: URL) throws -> [String: Any] {
        guard let value else { return [:] }
        guard let object = value as? [String: Any] else { throw InstallerError.unreadable(path: url.path) }
        return object
    }

    /// Keeps the first original as `<file>.keepawake-backup`, then writes atomically.
    private func save(_ object: [String: Any], to url: URL, replacing: Bool) throws {
        let fileManager = FileManager.default
        let backup = url.appendingPathExtension("keepawake-backup")
        if replacing && !fileManager.fileExists(atPath: backup.path) {
            try fileManager.copyItem(at: url, to: backup)
        }
        try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
        try (data + Data("\n".utf8)).write(to: url, options: .atomic)
    }

    // MARK: - Shell

    /// Apps don't inherit the Terminal PATH, so `claude` is looked up through a login
    /// shell plus the usual install folders.
    @Sendable static func loginShell(_ command: String) -> (status: Int32, output: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        let path = "export PATH=\"$PATH:$HOME/.local/bin:$HOME/.claude/local:/opt/homebrew/bin:/usr/local/bin\"; "
        process.arguments = ["-lc", path + command]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        process.standardInput = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            return (127, error.localizedDescription)
        }
        let output = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (process.terminationStatus, String(decoding: output, as: UTF8.self))
    }

    // MARK: - CLI

    /// `KeepAwake install|uninstall claude-code|cursor`
    static func runCLI(
        _ args: [String],
        installer: AgentInstaller,
        out: (String) -> Void,
        err: (String) -> Void
    ) -> Int32 {
        guard args.count == 2, let target = AgentTarget(rawValue: args[1]) else {
            err("usage: KeepAwake install|uninstall claude-code|cursor")
            return AgentCLI.usageError
        }
        do {
            let lines = args[0] == "install" ? try installer.install(target) : try installer.uninstall(target)
            lines.forEach(out)
            return AgentCLI.ok
        } catch {
            err(error.localizedDescription)
            return 1
        }
    }
}
