import Foundation
import Testing
@testable import KeepAwake

@MainActor
final class TestBattery {
    var state = BatteryState(percent: 80, isOnBattery: false, isCharging: false)
}

@MainActor
final class LivePIDs {
    var pids: Set<Int32> = []
}

@MainActor
struct ControllerAgentTests {
    private let defaults = UserDefaults(suiteName: "keepAwakeAgentTests-\(UUID().uuidString)")!
    private let statusURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("keepAwakeAgent-\(UUID().uuidString)/status.json")
    private let battery = TestBattery()
    private let live = LivePIDs()

    private func makeController() -> KeepAwakeController {
        let lid = LidSleepOverride(
            runner: FakeRunner(),
            fileExists: { _ in true },
            lidClosedCausesSleep: { false },
            helperScriptPath: "/x.sh",
            isSandboxed: false
        )
        let battery = battery
        let live = live
        return KeepAwakeController(
            defaults: defaults,
            lid: lid,
            playTimeUpSound: {},
            battery: BatteryMonitor(read: { battery.state }),
            statusURL: statusURL,
            isProcessAlive: { live.pids.contains($0) }
        )
    }

    private func hold(_ id: String, minutes: Int = 30, pid: Int32? = nil) -> AgentCommand {
        .hold(HoldRequest(id: id, name: id.uppercased(), minutes: minutes, pid: pid))
    }

    private var status: AgentStatus? { StatusFile.read(from: statusURL) }

    @Test func holdKeepsAwakeWithoutManual() {
        let controller = makeController()
        defer { controller.turnOff() }
        controller.handle(hold("a"))
        #expect(controller.isAwake)
        #expect(!controller.isActive)
        #expect(status?.awake == true)
        #expect(status?.holds.map(\.id) == ["a"])
        #expect(controller.statusText == "Active · held by A")
    }

    @Test func manualTimeUpKeepsHolds() {
        let controller = makeController()
        defer { controller.turnOff() }
        controller.start(minutes: 1)
        controller.handle(hold("a"))
        controller.tick(at: Date().addingTimeInterval(61))
        #expect(!controller.isActive)
        #expect(controller.isAwake)
    }

    @Test func turnOffClearsHolds() {
        let controller = makeController()
        controller.start(minutes: 15)
        controller.handle(hold("a"))
        controller.handle(hold("b"))
        controller.turnOff()
        #expect(!controller.isAwake)
        #expect(controller.holds.isEmpty)
        #expect(status?.awake == false)
        #expect(status?.holds.isEmpty == true)
    }

    @Test func expiredHoldDropped() {
        let controller = makeController()
        defer { controller.turnOff() }
        controller.handle(hold("a", minutes: 30))
        controller.tick(at: Date().addingTimeInterval(30 * 60 + 1))
        #expect(!controller.isAwake)
        #expect(status?.awake == false)
    }

    @Test func deadPidHoldDropped() {
        live.pids = [4242]
        let controller = makeController()
        defer { controller.turnOff() }
        controller.handle(hold("a", pid: 4242))
        controller.tick()
        #expect(controller.isAwake)
        live.pids = []
        controller.tick()
        #expect(!controller.isAwake)
    }

    @Test func releaseEndsOnlyThatHold() {
        let controller = makeController()
        defer { controller.turnOff() }
        controller.handle(hold("a"))
        controller.handle(hold("b"))
        controller.handle(.release(id: "a"))
        #expect(controller.holds.holds.map(\.id) == ["b"])
        controller.release(holdID: "b")
        #expect(!controller.isAwake)
    }

    @Test func agentControlDisabledIgnoresCommands() {
        let controller = makeController()
        defer { controller.turnOff() }
        controller.handle(hold("a"))
        controller.agentControlEnabled = false
        #expect(controller.holds.isEmpty)
        #expect(!controller.isAwake)
        controller.handle(hold("b"))
        controller.handle(.start(minutes: 5))
        #expect(!controller.isAwake)
        #expect(status?.agentControlEnabled == false)
    }

    @Test func urlStartAndStopDriveManualMode() {
        let controller = makeController()
        controller.handle(.start(minutes: 5))
        #expect(controller.isActive)
        controller.handle(hold("a"))
        controller.handle(.stop)
        #expect(!controller.isAwake)
    }

    @Test func batteryLowRefusesHold() {
        defaults.set(true, forKey: "batteryLimitEnabled")
        defaults.set(10, forKey: "batteryThreshold")
        battery.state = BatteryState(percent: 5, isOnBattery: true, isCharging: false)
        let controller = makeController()
        controller.handle(hold("a"))
        #expect(!controller.isAwake)
        #expect(controller.lastStopReason?.hasPrefix("Not started:") == true)
    }

    @Test func batteryDropClearsHolds() {
        defaults.set(true, forKey: "batteryLimitEnabled")
        defaults.set(10, forKey: "batteryThreshold")
        let controller = makeController()
        controller.handle(hold("a"))
        #expect(controller.isAwake)
        battery.state = BatteryState(percent: 5, isOnBattery: true, isCharging: false)
        controller.battery.refresh()
        #expect(!controller.isAwake)
        #expect(controller.holds.isEmpty)
    }
}
