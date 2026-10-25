import Foundation

/// What the app is doing, written for the CLI, hooks and MCP server to read.
struct AgentStatus: Codable, Equatable, Sendable {
    var awake: Bool
    /// End of the manual timer; nil with `manualAlways` false means no manual timer.
    var manualEndsAt: Date?
    var manualAlways: Bool
    var holds: [AgentHold]
    var agentControlEnabled: Bool
    var appPID: Int32
    var updated: Date
}

/// `~/Library/Application Support/keepAwake/status.json`, shared by the app and its clients.
enum StatusFile {
    static var defaultURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("keepAwake", isDirectory: true)
            .appendingPathComponent("status.json")
    }

    static func write(_ status: AgentStatus, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(status)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }

    static func read(from url: URL) -> AgentStatus? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(AgentStatus.self, from: data)
    }
}
