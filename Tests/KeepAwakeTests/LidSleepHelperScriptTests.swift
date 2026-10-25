import Foundation
import Testing

struct LidSleepHelperScriptTests {
    private static let script = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Resources/lid-sleep-helper.sh").path

    private func runHelper(_ arguments: [String]) -> (status: Int32, output: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = [Self.script] + arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        try? process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (process.terminationStatus, String(decoding: data, as: UTF8.self))
    }

    @Test func renderProducesExactRule() {
        let result = runHelper(["render", "mike"])
        #expect(result.status == 0)
        #expect(result.output.contains(
            "mike ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 1, /usr/bin/pmset -a disablesleep 0\n"
        ))
    }

    @Test(arguments: ["", "a b", "x;rm", "root\nALL", "-h", "../x"])
    func renderRejectsUnsafeUser(_ user: String) {
        #expect(runHelper(["render", user]).status != 0)
    }

    @Test func renderRequiresUser() {
        #expect(runHelper(["render"]).status != 0)
    }

    @Test func unknownCommandFails() {
        #expect(runHelper(["bogus"]).status != 0)
    }
}
