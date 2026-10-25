import Foundation
import IOKit.pwr_mgt

/// Thin wrapper around an IOKit power-management assertion.
/// The assertion is released automatically by the OS if the process exits.
final class SleepAssertion {
    private var assertionID: IOPMAssertionID?

    var isHeld: Bool { assertionID != nil }

    /// Acquires (or replaces) the assertion. Returns false if IOKit refused it.
    @discardableResult
    func acquire(preventDisplaySleep: Bool) -> Bool {
        release()

        // Display-sleep assertion also keeps the system awake.
        let type = preventDisplaySleep ? "PreventUserIdleDisplaySleep" : "PreventUserIdleSystemSleep"
        var id = IOPMAssertionID(0)
        let result = IOPMAssertionCreateWithName(
            type as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "keepAwake: user requested" as CFString,
            &id
        )
        guard result == kIOReturnSuccess else { return false }
        assertionID = id
        return true
    }

    func release() {
        guard let id = assertionID else { return }
        IOPMAssertionRelease(id)
        assertionID = nil
    }

    deinit {
        release()
    }
}
