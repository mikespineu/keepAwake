import AppKit
import Observation
import ServiceManagement
import UserNotifications

/// Holds keepAwake state and enforces the stop rules (time limit, battery limit).
@MainActor
@Observable
final class KeepAwakeController {
    private enum Key {
        static let batteryLimitEnabled = "batteryLimitEnabled"
        static let batteryThreshold = "batteryThreshold"
        static let preventDisplaySleep = "preventDisplaySleep"
        static let customDays = "customDays"
        static let customHours = "customHours"
        static let customMinutes = "customMinutes"
        static let keepAwakeWithLidClosed = "keepAwakeWithLidClosed"
        /// True while `pmset disablesleep` is on because of us. Persisted, so a
        /// crash or reboot can be cleaned up on the next launch.
        static let lidOverrideOwned = "lidOverrideOwned"
        static let agentControlEnabled = "agentControlEnabled"
    }

    /// Longest custom duration: exactly this many days.
    nonisolated static let maxCustomDays = 30

    private(set) var isActive = false
    /// nil while active means "always on".
    private(set) var endDate: Date?
    private(set) var now = Date()
    private(set) var lastStopReason: String?
    private(set) var launchAtLogin = SMAppService.mainApp.status == .enabled
    private(set) var keepAwakeWithLidClosed: Bool
    /// Problem with the lid-closed mode, shown under its toggle.
    private(set) var lidMessage: String?
    /// Agents keeping the Mac awake, independent of the manual timer.
    private(set) var holds = HoldBook()

    /// True while the manual timer runs or any agent holds the Mac awake.
    var isAwake: Bool { isActive || !holds.isEmpty }

    /// Set from loginwindow's notifications, whoever locked the screen.
    private(set) var isScreenLocked = false

    /// The display may sleep behind the lock screen; the Mac itself stays awake.
    var keepsDisplayOn: Bool { preventDisplaySleep && !isScreenLocked }

    /// Off: commands from agents and URLs are ignored and existing holds end.
    var agentControlEnabled: Bool {
        didSet {
            defaults.set(agentControlEnabled, forKey: Key.agentControlEnabled)
            if !agentControlEnabled { holds.removeAll() }
            syncAwakeState()
        }
    }

    var batteryLimitEnabled: Bool {
        didSet {
            defaults.set(batteryLimitEnabled, forKey: Key.batteryLimitEnabled)
            enforceBatteryLimit()
        }
    }

    var batteryThreshold: Int {
        didSet {
            defaults.set(batteryThreshold, forKey: Key.batteryThreshold)
            enforceBatteryLimit()
        }
    }

    var preventDisplaySleep: Bool {
        didSet {
            defaults.set(preventDisplaySleep, forKey: Key.preventDisplaySleep)
            if isAwake { assertion.acquire(preventDisplaySleep: keepsDisplayOn) }
        }
    }

    var customDays: Int {
        didSet {
            defaults.set(customDays, forKey: Key.customDays)
            // Cap the custom duration at exactly `maxCustomDays`.
            if customDays >= Self.maxCustomDays {
                customHours = 0
                customMinutes = 0
            }
        }
    }

    var customHours: Int {
        didSet { defaults.set(customHours, forKey: Key.customHours) }
    }

    var customMinutes: Int {
        didSet { defaults.set(customMinutes, forKey: Key.customMinutes) }
    }

    let battery: BatteryMonitor

    @ObservationIgnored private let assertion = SleepAssertion()
    @ObservationIgnored private let statusURL: URL?
    @ObservationIgnored private let isProcessAlive: (Int32) -> Bool
    @ObservationIgnored private let lid: LidSleepOverride
    @ObservationIgnored private var ticker: Timer?
    @ObservationIgnored private var terminationObserver: NSObjectProtocol?
    @ObservationIgnored private var screenLockObservers: [NSObjectProtocol] = []
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let playTimeUpSound: () -> Void

    init(
        defaults: UserDefaults = .standard,
        lid: LidSleepOverride = LidSleepOverride(),
        playTimeUpSound: @escaping () -> Void = { NSSound(named: "Glass")?.play() },
        battery: BatteryMonitor = BatteryMonitor(),
        /// Where agents read our state; nil writes nothing (tests, snapshots).
        statusURL: URL? = nil,
        isProcessAlive: @escaping (Int32) -> Bool = { kill($0, 0) == 0 || errno == EPERM }
    ) {
        self.defaults = defaults
        self.lid = lid
        self.playTimeUpSound = playTimeUpSound
        self.battery = battery
        self.statusURL = statusURL
        self.isProcessAlive = isProcessAlive
        defaults.register(defaults: [
            Key.batteryLimitEnabled: true,
            Key.batteryThreshold: 10,
            Key.preventDisplaySleep: false,
            Key.customDays: 0,
            Key.customHours: 1,
            Key.customMinutes: 0,
            Key.keepAwakeWithLidClosed: false,
            Key.agentControlEnabled: true,
        ])
        batteryLimitEnabled = defaults.bool(forKey: Key.batteryLimitEnabled)
        batteryThreshold = defaults.integer(forKey: Key.batteryThreshold)
        preventDisplaySleep = defaults.bool(forKey: Key.preventDisplaySleep)
        customDays = min(defaults.integer(forKey: Key.customDays), Self.maxCustomDays)
        customHours = defaults.integer(forKey: Key.customHours)
        customMinutes = defaults.integer(forKey: Key.customMinutes)
        keepAwakeWithLidClosed = defaults.bool(forKey: Key.keepAwakeWithLidClosed)
        agentControlEnabled = defaults.bool(forKey: Key.agentControlEnabled)

        battery.onChange = { [weak self] in self?.enforceBatteryLimit() }

        // Left on by a crash or reboot: the Mac would never sleep with the lid closed.
        releaseLidOverride()
        terminationObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.prepareForQuit() }
        }
        let center = DistributedNotificationCenter.default()
        screenLockObservers = [(ScreenLock.lockedNotification, true), (ScreenLock.unlockedNotification, false)].map { name, locked in
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.screenLockChanged(locked: locked) }
            }
        }
        writeStatus()
    }

    // MARK: - Activation

    /// Starts keeping the Mac awake. `minutes == nil` means no time limit.
    func start(minutes: Int?) {
        lastStopReason = nil
        lidMessage = nil

        if let reason = batteryLimitViolation() {
            lastStopReason = "Not started: \(reason)"
            return
        }
        guard holdAwake() else {
            lastStopReason = "The system refused the sleep assertion."
            return
        }

        now = Date()
        endDate = minutes.map { now.addingTimeInterval(TimeInterval($0 * 60)) }
        isActive = true
        syncAwakeState()
    }

    func startCustom() {
        let total = min(customDays * 24 * 60 + customHours * 60 + customMinutes, Self.maxCustomDays * 24 * 60)
        guard total > 0 else { return }
        start(minutes: total)
    }

    /// Ends the manual timer. Agent holds keep the Mac awake until they end too.
    func stop(reason: String? = nil) {
        isActive = false
        endDate = nil
        lastStopReason = reason.map { "Stopped: \($0)" }
        if let reason { notify(reason) }
        syncAwakeState()
    }

    /// Turn Off in the menu: the manual timer and every agent hold end.
    func turnOff() {
        holds.removeAll()
        stop()
    }

    func prepareForQuit() {
        turnOff()
    }

    // MARK: - Screen lock

    /// False in the sandboxed build, where the button is hidden.
    var screenLockAvailable: Bool { ScreenLock.isAvailable }

    /// Lock Screen in the menu. keepAwake and agents keep running behind it.
    func lockScreen() {
        ScreenLock.lock()
    }

    func screenLockChanged(locked: Bool) {
        guard locked != isScreenLocked else { return }
        isScreenLocked = locked
        if isAwake && preventDisplaySleep { assertion.acquire(preventDisplaySleep: keepsDisplayOn) }
    }

    // MARK: - Agents

    func handle(_ command: AgentCommand) {
        guard agentControlEnabled else { return }
        switch command {
        case .start(let minutes):
            start(minutes: minutes)
        case .stop:
            turnOff()
        case .hold(let request):
            if let reason = batteryLimitViolation() {
                lastStopReason = "Not started: \(reason)"
                return
            }
            guard holdAwake() else {
                lastStopReason = "The system refused the sleep assertion."
                return
            }
            holds.apply(request, now: Date())
            syncAwakeState()
        case .release(let id):
            release(holdID: id)
        }
    }

    func release(holdID: String) {
        guard holds.release(id: holdID) else { return }
        syncAwakeState()
    }

    // MARK: - Rules

    /// Takes the assertion unless it is already held. False when IOKit refuses it.
    private func holdAwake() -> Bool {
        assertion.isHeld || assertion.acquire(preventDisplaySleep: keepsDisplayOn)
    }

    /// Makes the assertion, lid override, ticker and status file match `isAwake`.
    private func syncAwakeState() {
        if isAwake {
            // Without the helper keepAwake still runs, just not with the lid closed.
            if keepAwakeWithLidClosed && !defaults.bool(forKey: Key.lidOverrideOwned) { applyLidOverride() }
        } else {
            assertion.release()
            releaseLidOverride()
        }
        updateTicker()
        writeStatus()
    }

    private func updateTicker() {
        guard endDate != nil || !holds.isEmpty else {
            ticker?.invalidate()
            ticker = nil
            return
        }
        guard ticker == nil else { return }

        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        // .common keeps the countdown running while the menu is open.
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    func tick(at date: Date = Date()) {
        now = date
        let ended = holds.prune(now: date, isAlive: isProcessAlive)
        if isActive, let endDate, now >= endDate {
            // Played directly, so it works even with notifications turned off.
            playTimeUpSound()
            stop(reason: "time is up.")
        } else if !ended.isEmpty {
            syncAwakeState()
        }
    }

    private func enforceBatteryLimit() {
        guard isAwake, let reason = batteryLimitViolation() else { return }
        holds.removeAll()
        stop(reason: reason)
    }

    private func writeStatus() {
        guard let statusURL else { return }
        let status = AgentStatus(
            awake: isAwake,
            manualEndsAt: isActive ? endDate : nil,
            manualAlways: isActive && endDate == nil,
            holds: holds.holds,
            agentControlEnabled: agentControlEnabled,
            appPID: getpid(),
            updated: Date()
        )
        try? StatusFile.write(status, to: statusURL)
    }

    /// The battery rule only applies while running on battery power.
    private func batteryLimitViolation() -> String? {
        let state = battery.state
        guard batteryLimitEnabled, state.isOnBattery, let percent = state.percent,
              percent < batteryThreshold
        else { return nil }
        return "battery \(percent)% < \(batteryThreshold)%."
    }

    // MARK: - Display helpers

    var remaining: TimeInterval? {
        guard isActive, let endDate else { return nil }
        return max(0, endDate.timeIntervalSince(now))
    }

    /// Compact text for the menu bar, e.g. "3d 4h", "1:05" (h:mm) or "12:30" (mm:ss).
    var menuBarText: String? {
        guard let remaining else { return nil }
        let total = Int(remaining.rounded(.up))
        let days = total / 86_400
        let hours = (total % 86_400) / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if days > 0 {
            return "\(days)d \(hours)h"
        }
        if hours > 0 {
            return String(format: "%d:%02d", hours, minutes)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    var statusText: String {
        guard isActive else {
            guard !holds.isEmpty else { return "Inactive" }
            return "Active · held by " + holds.holds.map(\.name).joined(separator: ", ")
        }
        guard let remaining, let endDate else { return "Active · always" }
        let total = Int(remaining.rounded(.up))
        let days = total / 86_400
        var countdown = String(format: "%d:%02d:%02d", (total % 86_400) / 3600, (total % 3600) / 60, total % 60)
        if days > 0 { countdown = "\(days)d " + countdown }
        // Show the date too once the end is not today.
        let until = Calendar.current.isDateInToday(endDate)
            ? endDate.formatted(date: .omitted, time: .shortened)
            : endDate.formatted(.dateTime.day().month(.abbreviated).hour().minute())
        return "Active · \(countdown) (until \(until))"
    }

    var batteryText: String {
        let state = battery.state
        guard let percent = state.percent else { return "No battery" }
        let source = state.isOnBattery ? "on battery" : (state.isCharging ? "charging" : "power adapter")
        return "Battery \(percent)% · \(source)"
    }

    // MARK: - Lid closed

    /// False in the sandboxed build, where the toggle is hidden.
    var lidModeAvailable: Bool { lid.isAvailable }

    var lidHelperInstalled: Bool { lid.isInstalled }

    /// Turning it on the first time installs the helper, which asks for an admin password.
    func setKeepAwakeWithLidClosed(_ enabled: Bool) async {
        lidMessage = nil
        if enabled && !lid.isInstalled {
            guard await lid.install() else {
                lidMessage = "Lid-closed mode needs your admin password."
                return
            }
        }
        keepAwakeWithLidClosed = enabled
        defaults.set(enabled, forKey: Key.keepAwakeWithLidClosed)
        guard isAwake else { return }
        if enabled {
            applyLidOverride()
        } else {
            releaseLidOverride()
        }
    }

    private func applyLidOverride() {
        if lid.enable() {
            defaults.set(true, forKey: Key.lidOverrideOwned)
            lidMessage = nil
        } else {
            lidMessage = "Lid-closed mode is unavailable: the helper is not installed."
        }
    }

    /// Only undoes an override we set ourselves, never one the user set with pmset.
    private func releaseLidOverride() {
        guard defaults.bool(forKey: Key.lidOverrideOwned) else { return }
        lid.disable()
        defaults.set(false, forKey: Key.lidOverrideOwned)
    }

    // MARK: - Launch at login

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            lastStopReason = "Launch at login: \(error.localizedDescription)"
        }
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    // MARK: - Notifications

    private func notify(_ body: String) {
        // UserNotifications crashes outside an app bundle (e.g. `swift run`).
        guard Bundle.main.bundleIdentifier != nil else { return }
        Task {
            let center = UNUserNotificationCenter.current()
            guard (try? await center.requestAuthorization(options: [.alert, .sound])) == true else { return }
            let content = UNMutableNotificationContent()
            content.title = "keepAwake stopped"
            content.body = body.prefix(1).uppercased() + body.dropFirst()
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            try? await center.add(request)
        }
    }
}
