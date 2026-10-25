import Foundation
import IOKit.ps
import Observation

struct BatteryState: Equatable {
    /// nil when the Mac has no internal battery.
    var percent: Int?
    var isOnBattery: Bool
    var isCharging: Bool
}

/// Reads the internal battery and listens for power-source change notifications.
@MainActor
@Observable
final class BatteryMonitor {
    private(set) var state: BatteryState

    @ObservationIgnored var onChange: (() -> Void)?
    @ObservationIgnored private var runLoopSource: CFRunLoopSource?

    init() {
        state = Self.read()
        startListening()
    }

    func refresh() {
        let newState = Self.read()
        guard newState != state else { return }
        state = newState
        onChange?()
    }

    private func startListening() {
        let context = Unmanaged.passUnretained(self).toOpaque()
        let callback: IOPowerSourceCallbackType = { context in
            guard let context else { return }
            let monitor = Unmanaged<BatteryMonitor>.fromOpaque(context).takeUnretainedValue()
            // The source is added to the main run loop, so we are on the main thread.
            MainActor.assumeIsolated { monitor.refresh() }
        }
        guard let source = IOPSNotificationCreateRunLoopSource(callback, context)?.takeRetainedValue() else {
            return
        }
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
        runLoopSource = source
    }

    private static func read() -> BatteryState {
        let fallback = BatteryState(percent: nil, isOnBattery: false, isCharging: false)
        guard
            let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
            let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef]
        else { return fallback }

        for source in sources {
            guard
                let description = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any],
                description[kIOPSTypeKey] as? String == kIOPSInternalBatteryType,
                let current = description[kIOPSCurrentCapacityKey] as? Int,
                let max = description[kIOPSMaxCapacityKey] as? Int, max > 0
            else { continue }

            let percent = Int((Double(current) / Double(max) * 100).rounded())
            let onBattery = description[kIOPSPowerSourceStateKey] as? String == kIOPSBatteryPowerValue
            let charging = description[kIOPSIsChargingKey] as? Bool ?? false
            return BatteryState(percent: percent, isOnBattery: onBattery, isCharging: charging)
        }
        return fallback
    }
}
