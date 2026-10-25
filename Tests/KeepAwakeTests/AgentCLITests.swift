import Foundation
import Testing
@testable import KeepAwake

struct AgentCLITests {
    private let app = FakeApp()

    private func run(_ args: [String]) -> (status: Int32, out: [String], err: [String]) {
        var out: [String] = []
        var err: [String] = []
        let status = AgentCLI.run(args, client: app.client, out: { out.append($0) }, err: { err.append($0) })
        return (status, out, err)
    }

    @Test func holdSendsUrlAndConfirms() {
        let result = run(["hold", "--id", "t", "--name", "Test", "--minutes", "5"])
        #expect(result.status == 0)
        #expect(app.commands == [.hold(HoldRequest(id: "t", name: "Test", minutes: 5, pid: nil))])
        #expect(result.out.joined().contains("Test"))
    }

    @Test func releaseConfirms() {
        _ = run(["hold", "--id", "t"])
        let result = run(["release", "--id", "t"])
        #expect(result.status == 0)
        #expect(app.commands.last == .release(id: "t"))
    }

    @Test(arguments: [["hold"], ["hold", "--id", "a", "--minutes", "x"], ["bogus"], ["start", "--minutes", "0"],
                      ["release"], ["hold", "--id"]])
    func usageErrorsExit64(_ args: [String]) {
        let result = run(args)
        #expect(result.status == 64)
        #expect(app.commands.isEmpty)
    }

    @Test func appNotRespondingExit69() {
        app.responds = false
        let result = run(["hold", "--id", "t"])
        #expect(result.status == 69)
        #expect(result.err.joined().contains("keepAwake did not respond"))
    }

    @Test func agentControlOffIsReported() {
        app.agentControlEnabled = false
        app.writeStatus()
        let result = run(["hold", "--id", "t"])
        #expect(result.status == 69)
        #expect(result.err.joined().contains("turned off"))
    }

    @Test func statusJsonPrintsFile() throws {
        app.writeStatus(manualAlways: true)
        let result = run(["status", "--json"])
        #expect(result.status == 0)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let printed = try decoder.decode(AgentStatus.self, from: Data(result.out.joined().utf8))
        #expect(printed == StatusFile.read(from: app.statusURL))
    }

    @Test func statusWhenNotRunningExit69() {
        let result = run(["status"])
        #expect(result.status == 69)
        #expect(result.out.joined().contains("not running"))
    }
}
