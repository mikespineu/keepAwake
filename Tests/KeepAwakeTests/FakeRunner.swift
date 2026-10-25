import Foundation
@testable import KeepAwake

/// Records every command instead of running it.
final class FakeRunner: CommandRunner, @unchecked Sendable {
    struct Call: Equatable {
        var path: String
        var args: [String]
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _detached: [Call] = []
    private var _terminated: [Int32] = []

    /// Exit status by "path arg1 arg2…", falling back to the path alone; 0 when missing.
    var results: [String: Int32] = [:]
    var nextPID: Int32 = 1000

    var calls: [Call] { lock.withLock { _calls } }
    var detached: [Call] { lock.withLock { _detached } }
    var terminated: [Int32] { lock.withLock { _terminated } }

    /// Commands run through `sudo`, as their pmset arguments.
    var sudoCalls: [[String]] { calls.filter { $0.path == "/usr/bin/sudo" }.map(\.args) }

    func ran(_ path: String) -> Bool { calls.contains { $0.path == path } }

    func run(_ path: String, _ arguments: [String]) -> CommandResult {
        lock.withLock { _calls.append(Call(path: path, args: arguments)) }
        let key = ([path] + arguments).joined(separator: " ")
        return CommandResult(status: results[key] ?? results[path] ?? 0, output: "")
    }

    func launchDetached(_ path: String, _ arguments: [String]) -> Int32? {
        lock.withLock {
            _detached.append(Call(path: path, args: arguments))
            return nextPID
        }
    }

    func terminate(_ pid: Int32) {
        lock.withLock { _terminated.append(pid) }
    }
}
