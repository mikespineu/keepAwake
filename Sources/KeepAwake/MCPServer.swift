import Foundation

/// `KeepAwake mcp`: a Model Context Protocol server on stdin/stdout, one JSON-RPC
/// message per line. Its hold watches this process, so it ends with the agent session.
final class MCPServer {
    static let supportedVersions = ["2025-11-25", "2025-06-18", "2025-03-26", "2024-11-05"]
    static let fallbackVersion = "2025-06-18"
    static let defaultMinutes = 60

    private let client: AgentClient
    private let pid: Int32
    private var clientName: String?
    private var holding = false

    private var holdID: String { "mcp:\(pid)" }

    init(client: AgentClient, pid: Int32 = getpid()) {
        self.client = client
        self.pid = pid
    }

    /// Reads messages until stdin closes, then lets the Mac sleep again.
    func run(input: FileHandle = .standardInput, output: FileHandle = .standardOutput) {
        var buffer = Data()
        while true {
            let chunk = input.availableData
            if chunk.isEmpty { break }
            buffer.append(chunk)
            while let newline = buffer.firstIndex(of: UInt8(ascii: "\n")) {
                let line = String(decoding: buffer[buffer.startIndex..<newline], as: UTF8.self)
                buffer.removeSubrange(buffer.startIndex...newline)
                guard !line.trimmingCharacters(in: .whitespaces).isEmpty,
                      let response = handle(line: line)
                else { continue }
                output.write(Data((response + "\n").utf8))
            }
        }
        if holding { _ = client.send(.release(id: holdID)) }
    }

    /// One message in, one response line out; nil for notifications.
    func handle(line: String) -> String? {
        guard let message = (try? JSONSerialization.jsonObject(with: Data(line.utf8))) as? [String: Any],
              let method = message["method"] as? String
        else { return encode(["jsonrpc": "2.0", "id": NSNull(), "error": ["code": -32700, "message": "Parse error"]]) }

        // No id: a notification, which never gets an answer.
        guard let id = message["id"] else { return nil }
        let params = message["params"] as? [String: Any] ?? [:]

        let result: [String: Any]
        switch method {
        case "initialize":
            result = initialize(params)
        case "ping":
            result = [:]
        case "tools/list":
            result = ["tools": Self.tools]
        case "tools/call":
            result = callTool(params["name"] as? String ?? "", params["arguments"] as? [String: Any] ?? [:])
        default:
            return encode(["jsonrpc": "2.0", "id": id, "error": ["code": -32601, "message": "Method not found: \(method)"]])
        }
        return encode(["jsonrpc": "2.0", "id": id, "result": result])
    }

    // MARK: - Methods

    private func initialize(_ params: [String: Any]) -> [String: Any] {
        clientName = (params["clientInfo"] as? [String: Any])?["name"] as? String
        let requested = params["protocolVersion"] as? String ?? ""
        return [
            "protocolVersion": Self.supportedVersions.contains(requested) ? requested : Self.fallbackVersion,
            "capabilities": ["tools": [String: Any]()],
            "serverInfo": [
                "name": "keepawake",
                "version": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev",
            ],
            "instructions": "Call keep_awake before long-running work (builds, test suites, model training, large downloads) so the Mac does not fall asleep, and allow_sleep when it is done.",
        ]
    }

    private func callTool(_ name: String, _ arguments: [String: Any]) -> [String: Any] {
        switch name {
        case "keep_awake": keepAwake(arguments)
        case "allow_sleep": allowSleep()
        case "keep_awake_status": status()
        default: Self.toolResult("Unknown tool: \(name)", isError: true)
        }
    }

    private func keepAwake(_ arguments: [String: Any]) -> [String: Any] {
        var minutes = Self.defaultMinutes
        if let value = arguments["minutes"] {
            guard let number = value as? NSNumber, number.doubleValue == number.doubleValue.rounded(),
                  (1...AgentCommand.holdMinutesMax).contains(number.intValue)
            else { return Self.toolResult("minutes must be a whole number from 1 to 1440.", isError: true) }
            minutes = number.intValue
        }
        let reason = (arguments["reason"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = reason.flatMap { $0.isEmpty ? nil : $0 } ?? clientName ?? "MCP client"
        let request = AgentCommand.hold(HoldRequest(id: holdID, name: name, minutes: minutes, pid: pid))
        // Parsed back from its URL, so the name is trimmed and truncated like any other hold.
        guard let command = AgentCommand(url: request.url) else {
            return Self.toolResult("Could not build the keepAwake command.", isError: true)
        }

        let id = holdID
        guard let status = client.sendAndConfirm(command, until: { $0.holds.contains { $0.id == id } }),
              let hold = status.holds.first(where: { $0.id == id })
        else { return notResponding() }
        holding = true
        return Self.toolResult("Keeping the Mac awake until \(AgentCLI.time(hold.expires)). Call allow_sleep when the work is done.")
    }

    private func allowSleep() -> [String: Any] {
        let id = holdID
        guard client.sendAndConfirm(.release(id: id), until: { !$0.holds.contains { $0.id == id } }) != nil else {
            return notResponding()
        }
        holding = false
        return Self.toolResult("Released. The Mac can sleep again unless something else keeps it awake.")
    }

    private func status() -> [String: Any] {
        guard let status = client.status() else { return Self.toolResult("keepAwake is not running.") }
        return Self.toolResult(AgentCLI.statusLines(status).joined(separator: "\n"))
    }

    private func notResponding() -> [String: Any] {
        if client.status()?.agentControlEnabled == false {
            return Self.toolResult("Agent control is turned off in the keepAwake menu (\"Let AI agents keep your Mac awake\").", isError: true)
        }
        return Self.toolResult(
            "keepAwake did not respond. Make sure keepAwake.app is installed and \"Let AI agents keep your Mac awake\" is on in its menu.",
            isError: true
        )
    }

    // MARK: - Encoding

    private static func toolResult(_ text: String, isError: Bool = false) -> [String: Any] {
        ["content": [["type": "text", "text": text]], "isError": isError]
    }

    private func encode(_ object: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: [.withoutEscapingSlashes]) else {
            return #"{"jsonrpc":"2.0","id":null,"error":{"code":-32603,"message":"Internal error"}}"#
        }
        return String(decoding: data, as: UTF8.self)
    }

    private static var emptySchema: [String: Any] { ["type": "object", "properties": [String: Any](), "additionalProperties": false] }

    static var tools: [[String: Any]] { [
        [
            "name": "keep_awake",
            "title": "Keep the Mac awake",
            "description": "Keep the Mac from sleeping while long-running work runs (builds, test suites, model training, downloads). The hold ends after `minutes`, when allow_sleep is called, or when this session ends. Call again to extend it.",
            "inputSchema": [
                "type": "object",
                "properties": [
                    "minutes": [
                        "type": "integer", "minimum": 1, "maximum": 1440, "default": 60,
                        "description": "How long to keep the Mac awake.",
                    ],
                    "reason": [
                        "type": "string", "maxLength": 40,
                        "description": "Shown in the keepAwake menu, e.g. \"nightly build\".",
                    ],
                ],
                "additionalProperties": false,
            ],
        ],
        [
            "name": "allow_sleep",
            "title": "Let the Mac sleep",
            "description": "End the hold made by keep_awake in this session, so the Mac can sleep again.",
            "inputSchema": emptySchema,
        ],
        [
            "name": "keep_awake_status",
            "title": "keepAwake status",
            "description": "Show whether keepAwake is keeping the Mac awake, and for whom.",
            "inputSchema": emptySchema,
        ],
    ] }
}
