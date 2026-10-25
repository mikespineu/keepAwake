import Foundation
import Testing
@testable import KeepAwake

@MainActor
final class SoundCounter {
    var count = 0
}

@MainActor
struct KeepAwakeControllerLidTests {
    private let enableArgs = ["-n", "/usr/bin/pmset", "-a", "disablesleep", "1"]
    private let disableArgs = ["-n", "/usr/bin/pmset", "-a", "disablesleep", "0"]

    private let runner = FakeRunner()
    private let defaults = UserDefaults(suiteName: "keepAwakeTests-\(UUID().uuidString)")!
    private let sounds = SoundCounter()

    init() {
        // A real low battery must not block start() in these tests.
        defaults.set(false, forKey: "batteryLimitEnabled")
    }

    private func makeController(installed: Bool = true) -> KeepAwakeController {
        let lid = LidSleepOverride(
            runner: runner,
            fileExists: { _ in installed },
            lidClosedCausesSleep: { false },
            helperScriptPath: "/x.sh",
            isSandboxed: false
        )
        let sounds = sounds
        return KeepAwakeController(defaults: defaults, lid: lid, playTimeUpSound: { sounds.count += 1 })
    }

    private var owned: Bool { defaults.bool(forKey: "lidOverrideOwned") }

    @Test func startEnablesOverrideWhenOptionOn() {
        defaults.set(true, forKey: "keepAwakeWithLidClosed")
        let controller = makeController()
        controller.start(minutes: 15)
        defer { controller.stop() }
        #expect(runner.sudoCalls == [enableArgs])
        #expect(owned)
    }

    @Test func startWithoutOptionDoesNotTouchPmset() {
        let controller = makeController()
        controller.start(minutes: 15)
        controller.stop()
        #expect(runner.sudoCalls.isEmpty)
    }

    @Test func stopDisablesOverride() {
        defaults.set(true, forKey: "keepAwakeWithLidClosed")
        let controller = makeController()
        controller.start(minutes: 15)
        controller.stop()
        #expect(runner.sudoCalls.last == disableArgs)
        #expect(!owned)
    }

    @Test func timerExpiryDisablesOverride() {
        defaults.set(true, forKey: "keepAwakeWithLidClosed")
        let controller = makeController()
        controller.start(minutes: 1)
        controller.tick(at: Date().addingTimeInterval(120))
        #expect(!controller.isActive)
        #expect(runner.sudoCalls.last == disableArgs)
    }

    @Test func timerExpiryPlaysSound() {
        let controller = makeController()
        controller.start(minutes: 1)
        controller.tick(at: Date().addingTimeInterval(30))
        #expect(sounds.count == 0)
        controller.tick(at: Date().addingTimeInterval(120))
        #expect(sounds.count == 1)
        controller.tick(at: Date().addingTimeInterval(180))
        #expect(sounds.count == 1)
    }

    @Test func manualStopIsSilent() {
        let controller = makeController()
        controller.start(minutes: 1)
        controller.stop()
        #expect(sounds.count == 0)
    }

    @Test func startWithoutHelperStillActivates() {
        defaults.set(true, forKey: "keepAwakeWithLidClosed")
        runner.results["/usr/bin/sudo"] = 1
        let controller = makeController(installed: false)
        controller.start(minutes: 15)
        defer { controller.stop() }
        #expect(controller.isActive)
        #expect(controller.lidMessage == "Lid-closed mode is unavailable: the helper is not installed.")
        #expect(!owned)
    }

    @Test func installCancelledKeepsToggleOff() async {
        runner.results["/usr/bin/osascript"] = 1
        let controller = makeController(installed: false)
        await controller.setKeepAwakeWithLidClosed(true)
        #expect(!controller.keepAwakeWithLidClosed)
        #expect(controller.lidMessage == "Lid-closed mode needs your admin password.")
        #expect(!defaults.bool(forKey: "keepAwakeWithLidClosed"))
    }

    @Test func installedHelperSkipsPasswordPrompt() async {
        let controller = makeController(installed: true)
        await controller.setKeepAwakeWithLidClosed(true)
        #expect(controller.keepAwakeWithLidClosed)
        #expect(!runner.ran("/usr/bin/osascript"))
        #expect(runner.sudoCalls.isEmpty)   // inactive: nothing to apply yet
    }

    @Test func togglingWhileActiveAppliesImmediately() async {
        let controller = makeController()
        controller.start(minutes: nil)
        defer { controller.stop() }
        await controller.setKeepAwakeWithLidClosed(true)
        #expect(runner.sudoCalls == [enableArgs])
        await controller.setKeepAwakeWithLidClosed(false)
        #expect(runner.sudoCalls == [enableArgs, disableArgs])
        #expect(!owned)
    }

    @Test func launchRecoversOwnedOverride() {
        defaults.set(true, forKey: "lidOverrideOwned")
        _ = makeController()
        #expect(runner.sudoCalls == [disableArgs])
        #expect(!owned)
    }

    @Test func launchIgnoresForeignOverride() {
        _ = makeController()
        #expect(runner.sudoCalls.isEmpty)
    }
}
