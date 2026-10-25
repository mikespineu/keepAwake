import Foundation
import Testing
@testable import KeepAwake

struct AgentCommandTests {
    private func command(_ string: String) -> AgentCommand? {
        AgentCommand(url: URL(string: string)!)
    }

    @Test func parsesStart() {
        #expect(command("keepawake://start?minutes=90") == .start(minutes: 90))
        #expect(command("keepawake://start") == .start(minutes: nil))
        #expect(command("KEEPAWAKE://stop") == .stop)
    }

    @Test(arguments: ["0", "-5", "abc", "43201"])
    func rejectsBadStartMinutes(_ minutes: String) {
        #expect(command("keepawake://start?minutes=\(minutes)") == nil)
    }

    @Test func holdDefaults() {
        #expect(command("keepawake://hold?id=claude-code:abc")
                == .hold(HoldRequest(id: "claude-code:abc", name: "claude-code:abc", minutes: 30, pid: nil)))
    }

    @Test func holdLimits() {
        #expect(command("keepawake://hold?id=a&minutes=1440") != nil)
        #expect(command("keepawake://hold?id=a&minutes=1441") == nil)
        #expect(command("keepawake://hold?id=a&pid=1") == .hold(HoldRequest(id: "a", name: "a", minutes: 30, pid: nil)))
    }

    @Test(arguments: ["", "a%20b", "x/y", String(repeating: "a", count: 129)])
    func rejectsBadHoldId(_ id: String) {
        #expect(command("keepawake://hold?id=\(id)") == nil)
    }

    @Test func nameTrimmedAndTruncated() {
        let long = String(repeating: "n", count: 60)
        guard case .hold(let request)? = command("keepawake://hold?id=a&name=%20\(long)") else {
            Issue.record("expected a hold")
            return
        }
        #expect(request.name == String(repeating: "n", count: 40))
    }

    @Test func roundTrip() {
        let samples: [AgentCommand] = [
            .start(minutes: nil), .start(minutes: 120), .stop, .release(id: "cursor:c1"),
            .hold(HoldRequest(id: "mcp:77", name: "Claude Code & tests", minutes: 45, pid: 4242)),
        ]
        for sample in samples {
            #expect(AgentCommand(url: sample.url) == sample)
        }
    }

    @Test func rejectsOtherSchemesAndCommands() {
        #expect(command("http://hold?id=a") == nil)
        #expect(command("keepawake://reboot") == nil)
        #expect(command("keepawake://release") == nil)
    }
}
