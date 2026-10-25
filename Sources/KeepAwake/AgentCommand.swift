import Foundation

/// An agent asking keepAwake to keep the Mac awake for a while.
struct HoldRequest: Equatable, Sendable {
    var id: String
    var name: String
    var minutes: Int
    /// Process to watch: the hold ends when it exits.
    var pid: Int32?
}

/// A command that reaches the app through a `keepawake://` URL.
enum AgentCommand: Equatable, Sendable {
    /// keepawake://start[?minutes=N], the same as the menu presets. nil means always.
    case start(minutes: Int?)
    /// keepawake://stop, the same as Turn Off in the menu.
    case stop
    /// keepawake://hold?id=&name=&minutes=&pid=
    case hold(HoldRequest)
    /// keepawake://release?id=
    case release(id: String)

    static let scheme = "keepawake"
    static let holdMinutesDefault = 30
    static let holdMinutesMax = 1440
    static let startMinutesMax = KeepAwakeController.maxCustomDays * 24 * 60
    static let nameMaxLength = 40

    init?(url: URL) {
        guard url.scheme?.lowercased() == Self.scheme,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else { return nil }

        var query: [String: String] = [:]
        for item in components.queryItems ?? [] {
            query[item.name] = item.value ?? ""
        }

        switch components.host?.lowercased() {
        case "start":
            guard let raw = query["minutes"] else {
                self = .start(minutes: nil)
                return
            }
            guard let minutes = Int(raw), (1...Self.startMinutesMax).contains(minutes) else { return nil }
            self = .start(minutes: minutes)
        case "stop":
            self = .stop
        case "hold":
            guard let id = query["id"], Self.isValidID(id) else { return nil }
            var minutes = Self.holdMinutesDefault
            if let raw = query["minutes"] {
                guard let value = Int(raw), (1...Self.holdMinutesMax).contains(value) else { return nil }
                minutes = value
            }
            let trimmed = (query["name"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let name = String((trimmed.isEmpty ? id : trimmed).prefix(Self.nameMaxLength))
            // pid 0 and 1 (launchd) are never worth watching.
            let pid = query["pid"].flatMap { Int32($0) }.flatMap { $0 > 1 ? $0 : nil }
            self = .hold(HoldRequest(id: id, name: name, minutes: minutes, pid: pid))
        case "release":
            guard let id = query["id"], Self.isValidID(id) else { return nil }
            self = .release(id: id)
        default:
            return nil
        }
    }

    var url: URL {
        var components = URLComponents()
        components.scheme = Self.scheme
        var items: [URLQueryItem] = []
        switch self {
        case .start(let minutes):
            components.host = "start"
            if let minutes { items.append(URLQueryItem(name: "minutes", value: String(minutes))) }
        case .stop:
            components.host = "stop"
        case .hold(let request):
            components.host = "hold"
            items.append(URLQueryItem(name: "id", value: request.id))
            items.append(URLQueryItem(name: "name", value: request.name))
            items.append(URLQueryItem(name: "minutes", value: String(request.minutes)))
            if let pid = request.pid { items.append(URLQueryItem(name: "pid", value: String(pid))) }
        case .release(let id):
            components.host = "release"
            items.append(URLQueryItem(name: "id", value: id))
        }
        if !items.isEmpty {
            // Encoded by hand: `queryItems` leaves "&" and "+" in values, which would split or change them.
            components.percentEncodedQueryItems = items.map {
                URLQueryItem(name: $0.name, value: $0.value?.addingPercentEncoding(withAllowedCharacters: Self.queryValueAllowed))
            }
        }
        return components.url!
    }

    /// `^[A-Za-z0-9._:-]{1,128}$`
    static func isValidID(_ id: String) -> Bool {
        id.range(of: "^[A-Za-z0-9._:-]{1,128}$", options: .regularExpression) != nil
    }

    private static let queryValueAllowed: CharacterSet = {
        var set = CharacterSet.urlQueryAllowed
        set.remove(charactersIn: "&=+?#")
        return set
    }()
}
