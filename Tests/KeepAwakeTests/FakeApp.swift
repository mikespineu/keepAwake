import Foundation
@testable import KeepAwake

/// Stands in for the running app: records the URLs clients open and, when
/// `responds` is on, writes the status file the way the app would.
final class FakeApp: @unchecked Sendable {
    let statusURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("keepAwakeFakeApp-\(UUID().uuidString)/status.json")

    private let lock = NSLock()
    private var _commands: [AgentCommand] = []
    private var _holds: [AgentHold] = []
    private var _clock = Date(timeIntervalSince1970: 1_800_000_000)

    var responds = true
    var opens = true
    var agentControlEnabled = true

    var commands: [AgentCommand] { lock.withLock { _commands } }

    var client: AgentClient {
        AgentClient(
            statusURL: statusURL,
            openURL: { [self] url in open(url) },
            isAlive: { _ in true },
            sleep: { [self] seconds in lock.withLock { _clock.addTimeInterval(seconds) } },
            now: { [self] in lock.withLock { _clock } }
        )
    }

    private func open(_ url: URL) -> Bool {
        guard opens else { return false }
        guard let command = AgentCommand(url: url) else { return true }
        lock.withLock { _commands.append(command) }
        guard responds, agentControlEnabled else { return true }
        let now = lock.withLock { _clock }
        lock.withLock {
            switch command {
            case .hold(let request):
                _holds.removeAll { $0.id == request.id }
                _holds.append(AgentHold(id: request.id, name: request.name,
                                        expires: now.addingTimeInterval(TimeInterval(request.minutes * 60)), pid: request.pid))
            case .release(let id):
                _holds.removeAll { $0.id == id }
            case .stop:
                _holds.removeAll()
            case .start:
                break
            }
        }
        writeStatus(manualAlways: command == .start(minutes: nil))
        return true
    }

    func writeStatus(manualAlways: Bool = false) {
        let (holds, now) = lock.withLock { (_holds, _clock) }
        let status = AgentStatus(
            awake: manualAlways || !holds.isEmpty,
            manualEndsAt: nil,
            manualAlways: manualAlways,
            holds: holds,
            agentControlEnabled: agentControlEnabled,
            appPID: getpid(),
            updated: now
        )
        try? StatusFile.write(status, to: statusURL)
    }
}
