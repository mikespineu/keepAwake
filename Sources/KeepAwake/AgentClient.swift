import Foundation

/// Talks to the running app: commands go out as `keepawake://` URLs, and the
/// app's answer comes back through the status file.
struct AgentClient: Sendable {
    var statusURL: URL = StatusFile.defaultURL
    var openURL: @Sendable (URL) -> Bool = AgentClient.openInBackground
    var isAlive: @Sendable (Int32) -> Bool = { kill($0, 0) == 0 || errno == EPERM }
    var sleep: @Sendable (TimeInterval) -> Void = { Thread.sleep(forTimeInterval: $0) }
    var now: @Sendable () -> Date = Date.init

    /// Hands the URL to Launch Services, which starts the app when it isn't running.
    func send(_ command: AgentCommand) -> Bool {
        openURL(command.url)
    }

    /// The app's current state, or nil when it isn't running.
    func status() -> AgentStatus? {
        guard let status = StatusFile.read(from: statusURL), isAlive(status.appPID) else { return nil }
        return status
    }

    /// Sends the command and waits until the app has written a status that satisfies `until`.
    func sendAndConfirm(
        _ command: AgentCommand,
        timeout: TimeInterval = 3,
        until: (AgentStatus) -> Bool
    ) -> AgentStatus? {
        // The status file keeps whole seconds only.
        let sent = Date(timeIntervalSince1970: now().timeIntervalSince1970.rounded(.down))
        let deadline = now().addingTimeInterval(timeout)
        guard send(command) else { return nil }
        while true {
            if let status = status(), status.updated >= sent, until(status) { return status }
            if now() >= deadline { return nil }
            sleep(0.1)
        }
    }

    @Sendable static func openInBackground(_ url: URL) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-g", url.absoluteString]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            return false
        }
        process.waitUntilExit()
        return process.terminationStatus == 0
    }
}
