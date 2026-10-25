import Foundation
import Testing
@testable import KeepAwake

struct MCPServerTests {
    private let app = FakeApp()

    private func makeServer() -> MCPServer {
        MCPServer(client: app.client, pid: 777)
    }

    private func call(_ server: MCPServer, _ message: [String: Any]) -> [String: Any]? {
        let data = try! JSONSerialization.data(withJSONObject: message)
        guard let line = server.handle(line: String(decoding: data, as: UTF8.self)) else { return nil }
        #expect(!line.contains("\n"))
        return try? JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any]
    }

    private func initialize(_ server: MCPServer, version: String = "2025-06-18") -> [String: Any]? {
        call(server, ["jsonrpc": "2.0", "id": 1, "method": "initialize",
                      "params": ["protocolVersion": version, "capabilities": [:] as [String: Any],
                                 "clientInfo": ["name": "claude-code", "version": "1"]]])
    }

    private func tool(_ server: MCPServer, _ name: String, _ arguments: [String: Any] = [:]) -> [String: Any]? {
        let response = call(server, ["jsonrpc": "2.0", "id": "c1", "method": "tools/call",
                                     "params": ["name": name, "arguments": arguments]])
        return response?["result"] as? [String: Any]
    }

    private func text(_ result: [String: Any]?) -> String {
        ((result?["content"] as? [[String: Any]])?.first?["text"] as? String) ?? ""
    }

    @Test func initializeEchoesSupportedVersion() {
        let result = initialize(makeServer())?["result"] as? [String: Any]
        #expect(result?["protocolVersion"] as? String == "2025-06-18")
        #expect((result?["serverInfo"] as? [String: Any])?["name"] as? String == "keepawake")
        #expect(result?["capabilities"] as? [String: Any] != nil)
        #expect((result?["instructions"] as? String)?.contains("keep_awake") == true)
    }

    @Test func initializeFallsBackForUnknownVersion() {
        let result = initialize(makeServer(), version: "2099-01-01")?["result"] as? [String: Any]
        #expect(result?["protocolVersion"] as? String == "2025-06-18")
    }

    @Test func listsThreeTools() {
        let server = makeServer()
        let response = call(server, ["jsonrpc": "2.0", "id": 2, "method": "tools/list"])
        let tools = (response?["result"] as? [String: Any])?["tools"] as? [[String: Any]]
        #expect(tools?.compactMap { $0["name"] as? String } == ["keep_awake", "allow_sleep", "keep_awake_status"])
        #expect(tools?.allSatisfy { $0["inputSchema"] is [String: Any] } == true)
    }

    @Test func keepAwakeHoldsWithServerPid() {
        let server = makeServer()
        _ = initialize(server)
        let result = tool(server, "keep_awake", ["minutes": 120, "reason": "nightly build"])
        #expect(app.commands == [.hold(HoldRequest(id: "mcp:777", name: "nightly build", minutes: 120, pid: 777))])
        #expect(result?["isError"] as? Bool == false)
        #expect(text(result).contains("allow_sleep"))
    }

    @Test func keepAwakeDefaultsToClientNameAnd60Minutes() {
        let server = makeServer()
        _ = initialize(server)
        _ = tool(server, "keep_awake")
        #expect(app.commands == [.hold(HoldRequest(id: "mcp:777", name: "claude-code", minutes: 60, pid: 777))])
    }

    @Test(arguments: [5000, 0])
    func keepAwakeOutOfRange(_ minutes: Int) {
        let result = tool(makeServer(), "keep_awake", ["minutes": minutes])
        #expect(result?["isError"] as? Bool == true)
        #expect(app.commands.isEmpty)
    }

    @Test func appDownIsToolError() {
        app.responds = false
        let result = tool(makeServer(), "keep_awake", ["minutes": 10])
        #expect(result?["isError"] as? Bool == true)
        #expect(text(result).contains("did not respond"))
    }

    @Test func allowSleepReleases() {
        let server = makeServer()
        _ = tool(server, "keep_awake")
        let result = tool(server, "allow_sleep")
        #expect(app.commands.last == .release(id: "mcp:777"))
        #expect(result?["isError"] as? Bool == false)
    }

    @Test func statusDescribesHolds() {
        let server = makeServer()
        _ = tool(server, "keep_awake", ["reason": "tests"])
        #expect(text(tool(server, "keep_awake_status")).contains("tests"))
    }

    @Test func notificationGetsNoResponse() {
        #expect(makeServer().handle(line: #"{"jsonrpc":"2.0","method":"notifications/initialized"}"#) == nil)
    }

    @Test func pingAnswersEmptyResult() {
        let response = call(makeServer(), ["jsonrpc": "2.0", "id": 9, "method": "ping"])
        #expect(response?["id"] as? Int == 9)
        #expect((response?["result"] as? [String: Any])?.isEmpty == true)
    }

    @Test func unknownMethod() {
        let response = call(makeServer(), ["jsonrpc": "2.0", "id": 3, "method": "resources/list"])
        #expect((response?["error"] as? [String: Any])?["code"] as? Int == -32601)
        #expect(response?["id"] as? Int == 3)
    }

    @Test func parseError() throws {
        let line = try #require(makeServer().handle(line: "{oops"))
        let response = try JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any]
        #expect((response?["error"] as? [String: Any])?["code"] as? Int == -32700)
        #expect(response?["id"] is NSNull)
    }

    @Test func eofReleasesHold() throws {
        let server = makeServer()
        let input = Pipe()
        let message = #"{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"keep_awake","arguments":{}}}"#
        input.fileHandleForWriting.write(Data((message + "\n").utf8))
        try input.fileHandleForWriting.close()
        server.run(input: input.fileHandleForReading, output: .nullDevice)
        #expect(app.commands.count == 2)
        #expect(app.commands.last == .release(id: "mcp:777"))
    }
}
