import Foundation
import Testing
@testable import KeepAwake

@MainActor
struct LidSleepOverrideTests {
    private let enableArgs = ["-n", "/usr/bin/pmset", "-a", "disablesleep", "1"]
    private let disableArgs = ["-n", "/usr/bin/pmset", "-a", "disablesleep", "0"]

    @Test func enableRunsPmsetAndStartsWatchdog() {
        let runner = FakeRunner()
        let lid = LidSleepOverride(runner: runner, appPID: 777)
        #expect(lid.enable())
        #expect(runner.calls == [.init(path: "/usr/bin/sudo", args: enableArgs)])
        #expect(runner.detached == [
            .init(path: "/bin/sh", args: ["-c", LidSleepOverride.watchdogScript, "keepawake-watchdog", "777"]),
        ])
    }

    @Test func enableFailsWhenSudoRefuses() {
        let runner = FakeRunner()
        runner.results["/usr/bin/sudo -n /usr/bin/pmset -a disablesleep 1"] = 1
        let lid = LidSleepOverride(runner: runner)
        #expect(!lid.enable())
        #expect(runner.detached.isEmpty)
    }

    @Test func enableTwiceKeepsOneWatchdog() {
        let runner = FakeRunner()
        runner.nextPID = 4242
        let lid = LidSleepOverride(runner: runner)
        #expect(lid.enable())
        #expect(lid.enable())
        #expect(runner.detached.count == 1)
    }

    @Test func disableResetsAndStopsWatchdog() {
        let runner = FakeRunner()
        runner.nextPID = 4242
        let lid = LidSleepOverride(runner: runner, lidClosedCausesSleep: { false })
        _ = lid.enable()
        lid.disable()
        #expect(runner.calls.last == .init(path: "/usr/bin/sudo", args: disableArgs))
        #expect(runner.terminated == [4242])
    }

    @Test func disableSleepsWhenLidClosed() {
        let runner = FakeRunner()
        let lid = LidSleepOverride(runner: runner, lidClosedCausesSleep: { true })
        lid.disable()
        #expect(runner.calls == [
            .init(path: "/usr/bin/sudo", args: disableArgs),
            .init(path: "/usr/bin/pmset", args: ["sleepnow"]),
        ])
    }

    @Test func disableKeepsAwakeWhenLidOpen() {
        let runner = FakeRunner()
        let lid = LidSleepOverride(runner: runner, lidClosedCausesSleep: { false })
        lid.disable()
        #expect(!runner.ran("/usr/bin/pmset"))
    }

    @Test func watchdogScriptResetsAndSleeps() {
        let script = LidSleepOverride.watchdogScript
        #expect(script.contains("/bin/kill -0 \"$1\""))
        #expect(script.contains("/usr/bin/sudo -n /usr/bin/pmset -a disablesleep 0"))
        #expect(script.contains("AppleClamshellCausesSleep"))
        #expect(script.contains("/usr/bin/pmset sleepnow"))
    }

    @Test func availability() {
        let runner = FakeRunner()
        #expect(LidSleepOverride(runner: runner, helperScriptPath: "/x.sh", isSandboxed: false).isAvailable)
        #expect(!LidSleepOverride(runner: runner, helperScriptPath: "/x.sh", isSandboxed: true).isAvailable)
        #expect(!LidSleepOverride(runner: runner, helperScriptPath: nil, isSandboxed: false).isAvailable)
    }

    @Test func installedWhenSudoersFileExists() {
        var checked: [String] = []
        let lid = LidSleepOverride(runner: FakeRunner(), fileExists: { checked.append($0); return true })
        #expect(lid.isInstalled)
        #expect(checked == ["/etc/sudoers.d/keepawake"])
    }
}
