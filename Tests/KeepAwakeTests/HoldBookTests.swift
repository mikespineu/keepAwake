import Foundation
import Testing
@testable import KeepAwake

struct HoldBookTests {
    private let t0 = Date(timeIntervalSince1970: 1_000_000)

    private func request(_ id: String, name: String? = nil, minutes: Int = 30, pid: Int32? = nil) -> HoldRequest {
        HoldRequest(id: id, name: name ?? id, minutes: minutes, pid: pid)
    }

    @Test func renewReplacesNotDuplicates() {
        var book = HoldBook()
        book.apply(request("a", name: "Old"), now: t0)
        book.apply(request("a", name: "New"), now: t0.addingTimeInterval(600))
        #expect(book.holds.count == 1)
        #expect(book.holds[0].name == "New")
        #expect(book.holds[0].expires == t0.addingTimeInterval(600 + 30 * 60))
    }

    @Test func pruneExpiryBoundary() {
        var book = HoldBook()
        book.apply(request("a", minutes: 1), now: t0)
        let early = book.prune(now: t0.addingTimeInterval(59), isAlive: { _ in true })
        #expect(early.isEmpty)
        let due = book.prune(now: t0.addingTimeInterval(60), isAlive: { _ in true })
        #expect(due.map(\.id) == ["a"])
        #expect(book.isEmpty)
    }

    @Test func pruneDeadPid() {
        var book = HoldBook()
        book.apply(request("dead", pid: 4242), now: t0)
        book.apply(request("nopid"), now: t0)
        let removed = book.prune(now: t0, isAlive: { $0 != 4242 })
        #expect(removed.map(\.id) == ["dead"])
        #expect(book.holds.map(\.id) == ["nopid"])
    }

    @Test func releaseUnknownReturnsFalse() {
        var book = HoldBook()
        book.apply(request("a"), now: t0)
        let unknown = book.release(id: "b")
        let known = book.release(id: "a")
        #expect(!unknown)
        #expect(known)
        #expect(book.isEmpty)
    }
}

struct StatusFileTests {
    private let folder = FileManager.default.temporaryDirectory
        .appendingPathComponent("keepAwakeStatus-\(UUID().uuidString)", isDirectory: true)
    private var url: URL { folder.appendingPathComponent("status.json") }

    private let sample = AgentStatus(
        awake: true,
        manualEndsAt: Date(timeIntervalSince1970: 2_000_000),
        manualAlways: false,
        holds: [AgentHold(id: "a", name: "Claude Code", expires: Date(timeIntervalSince1970: 2_000_100), pid: 42)],
        agentControlEnabled: true,
        appPID: 123,
        updated: Date(timeIntervalSince1970: 1_999_000)
    )

    @Test func roundTrip() throws {
        try StatusFile.write(sample, to: url)
        #expect(StatusFile.read(from: url) == sample)
    }

    @Test func missingFileIsNil() {
        #expect(StatusFile.read(from: url) == nil)
    }

    @Test func garbageIsNil() throws {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try Data("{oops".utf8).write(to: url)
        #expect(StatusFile.read(from: url) == nil)
    }
}
