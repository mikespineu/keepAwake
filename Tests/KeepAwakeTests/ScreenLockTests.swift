import Foundation
import Testing
@testable import KeepAwake

@MainActor
struct ScreenLockTests {
    private let defaults = UserDefaults(suiteName: "keepAwakeScreenLockTests-\(UUID().uuidString)")!

    private func makeController() -> KeepAwakeController {
        let lid = LidSleepOverride(
            runner: FakeRunner(),
            fileExists: { _ in true },
            lidClosedCausesSleep: { false },
            helperScriptPath: "/x.sh",
            isSandboxed: false
        )
        let battery = BatteryMonitor(read: { BatteryState(percent: 80, isOnBattery: false, isCharging: false) })
        return KeepAwakeController(defaults: defaults, lid: lid, playTimeUpSound: {}, battery: battery)
    }

    @Test func lockFunctionResolvesOutsideSandbox() {
        #expect(ScreenLock.isAvailable)
    }

    @Test func displayMaySleepWhileLocked() {
        let controller = makeController()
        defer { controller.turnOff() }
        controller.preventDisplaySleep = true
        controller.start(minutes: nil)
        #expect(controller.keepsDisplayOn)

        controller.screenLockChanged(locked: true)
        #expect(controller.isScreenLocked)
        #expect(!controller.keepsDisplayOn)
        #expect(controller.isAwake)

        controller.screenLockChanged(locked: false)
        #expect(controller.keepsDisplayOn)
        #expect(controller.isAwake)
    }

    @Test func lockWithoutDisplayOptionChangesNothing() {
        let controller = makeController()
        defer { controller.turnOff() }
        controller.start(minutes: 30)
        controller.screenLockChanged(locked: true)
        #expect(!controller.keepsDisplayOn)
        #expect(controller.isAwake)
        #expect(controller.isActive)
    }

    @Test func startingWhileLockedKeepsOnlyTheSystemAwake() {
        let controller = makeController()
        defer { controller.turnOff() }
        controller.preventDisplaySleep = true
        controller.screenLockChanged(locked: true)
        controller.handle(.hold(HoldRequest(id: "a", name: "A", minutes: 30, pid: nil)))
        #expect(controller.isAwake)
        #expect(!controller.keepsDisplayOn)
    }
}
