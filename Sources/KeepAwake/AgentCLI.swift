import Foundation

/// `KeepAwake hold|release|start|stop|status …`, for scripts and agents.
enum AgentCLI {
    static let commands: Set<String> = ["hold", "release", "start", "stop", "status"]

    static let ok: Int32 = 0
    static let usageError: Int32 = 64
    static let unavailable: Int32 = 69

    static let usage = """
        usage: KeepAwake hold --id ID [--name NAME] [--minutes 1-1440] [--pid PID]
               KeepAwake release --id ID
               KeepAwake start [--minutes 1-43200]
               KeepAwake stop
               KeepAwake status [--json]
        """

    static func run(
        _ args: [String],
        client: AgentClient,
        out: (String) -> Void,
        err: (String) -> Void
    ) -> Int32 {
        guard let name = args.first, commands.contains(name),
              let options = parseOptions(Array(args.dropFirst()))
        else {
            err(usage)
            return usageError
        }

        if name == "status" {
            return printStatus(client: client, json: options.flags.contains("json"), out: out)
        }

        guard options.flags.isEmpty, let command = command(name, options.values) else {
            err(usage)
            return usageError
        }

        guard let status = client.sendAndConfirm(command, until: { confirms(command, $0) }) else {
            if client.status()?.agentControlEnabled == false {
                err("Agent control is turned off in the keepAwake menu.")
            } else {
                err("keepAwake did not respond. Make sure keepAwake.app is installed.")
            }
            return unavailable
        }

        switch command {
        case .hold(let request):
            let until = status.holds.first { $0.id == request.id }?.expires
            out("Holding until \(until.map(time) ?? "?") (\(request.name))")
        case .release(let id):
            out("Released \(id)")
        case .start:
            out(status.manualEndsAt.map { "Awake until \(time($0))" } ?? "Awake until you turn it off")
        case .stop:
            out("keepAwake is off")
        }
        return ok
    }

    // MARK: - Parsing

    private struct Options {
        var values: [String: String] = [:]
        var flags: Set<String> = []
    }

    private static let valueOptions: Set<String> = ["id", "name", "minutes", "pid"]
    private static let flagOptions: Set<String> = ["json"]

    private static func parseOptions(_ args: [String]) -> Options? {
        var options = Options()
        var index = 0
        while index < args.count {
            guard args[index].hasPrefix("--") else { return nil }
            let key = String(args[index].dropFirst(2))
            if flagOptions.contains(key) {
                options.flags.insert(key)
                index += 1
            } else if valueOptions.contains(key), index + 1 < args.count {
                options.values[key] = args[index + 1]
                index += 2
            } else {
                return nil
            }
        }
        return options
    }

    /// Builds the URL from the raw options, so `AgentCommand(url:)` does all the validating.
    private static func command(_ name: String, _ values: [String: String]) -> AgentCommand? {
        let allowed: Set<String> = switch name {
        case "hold": ["id", "name", "minutes", "pid"]
        case "release": ["id"]
        case "start": ["minutes"]
        default: []
        }
        guard Set(values.keys).isSubset(of: allowed) else { return nil }
        var components = URLComponents()
        components.scheme = AgentCommand.scheme
        components.host = name
        if !values.isEmpty {
            components.queryItems = values.sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        return components.url.flatMap(AgentCommand.init(url:))
    }

    static func confirms(_ command: AgentCommand, _ status: AgentStatus) -> Bool {
        switch command {
        case .hold(let request): status.holds.contains { $0.id == request.id }
        case .release(let id): !status.holds.contains { $0.id == id }
        case .start: status.manualAlways || status.manualEndsAt != nil
        case .stop: !status.awake
        }
    }

    // MARK: - Output

    private static func printStatus(client: AgentClient, json: Bool, out: (String) -> Void) -> Int32 {
        guard let status = client.status() else {
            out("keepAwake is not running.")
            return unavailable
        }
        if json {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            out((try? encoder.encode(status)).map { String(decoding: $0, as: UTF8.self) } ?? "{}")
            return ok
        }
        statusLines(status).forEach(out)
        return ok
    }

    static func statusLines(_ status: AgentStatus) -> [String] {
        var lines = ["Awake: \(status.awake ? "yes" : "no")"]
        if status.manualAlways {
            lines.append("Manual: until you turn it off")
        } else if let end = status.manualEndsAt {
            lines.append("Manual: until \(time(end))")
        }
        for hold in status.holds {
            lines.append("Hold: \(hold.name) until \(time(hold.expires)) (\(hold.id))")
        }
        lines.append("Agent control: \(status.agentControlEnabled ? "on" : "off")")
        return lines
    }

    static func time(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }
}
