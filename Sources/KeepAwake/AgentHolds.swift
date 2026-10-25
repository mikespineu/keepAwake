import Foundation

/// One agent keeping the Mac awake until `expires`, or until `pid` exits.
struct AgentHold: Codable, Equatable, Identifiable, Sendable {
    let id: String
    var name: String
    var expires: Date
    var pid: Int32?
}

/// The live agent holds, in the order they were first made.
struct HoldBook: Equatable {
    private(set) var holds: [AgentHold] = []

    var isEmpty: Bool { holds.isEmpty }

    /// Adds the hold, or renews it in place when the id is already holding.
    mutating func apply(_ request: HoldRequest, now: Date) {
        let hold = AgentHold(
            id: request.id,
            name: request.name,
            expires: now.addingTimeInterval(TimeInterval(request.minutes * 60)),
            pid: request.pid
        )
        if let index = holds.firstIndex(where: { $0.id == request.id }) {
            holds[index] = hold
        } else {
            holds.append(hold)
        }
    }

    @discardableResult
    mutating func release(id: String) -> Bool {
        guard let index = holds.firstIndex(where: { $0.id == id }) else { return false }
        holds.remove(at: index)
        return true
    }

    mutating func removeAll() {
        holds.removeAll()
    }

    /// Drops holds that expired or whose process exited, and returns them.
    mutating func prune(now: Date, isAlive: (Int32) -> Bool) -> [AgentHold] {
        let removed = holds.filter { $0.expires <= now || $0.pid.map { !isAlive($0) } ?? false }
        holds.removeAll { hold in removed.contains { $0.id == hold.id } }
        return removed
    }
}
