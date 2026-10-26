import Foundation

/// Locks the screen the way Ctrl-Cmd-Q does. The session keeps running, so agents
/// and keepAwake's assertion carry on behind the lock screen.
enum ScreenLock {
    /// Sent by loginwindow when the screen locks and unlocks, whoever locked it.
    static let lockedNotification = Notification.Name("com.apple.screenIsLocked")
    static let unlockedNotification = Notification.Name("com.apple.screenIsUnlocked")

    private typealias LockFunction = @convention(c) () -> Int32

    /// `SACLockScreenImmediate` from the private login framework: what the Apple menu's
    /// Lock Screen calls. It needs no permissions and locks whatever the password settings.
    private static let lockFunction: LockFunction? = {
        let path = "/System/Library/PrivateFrameworks/login.framework/Versions/Current/login"
        guard let handle = dlopen(path, RTLD_LAZY), let symbol = dlsym(handle, "SACLockScreenImmediate") else {
            return nil
        }
        return unsafeBitCast(symbol, to: LockFunction.self)
    }()

    /// False in the sandboxed (App Store) build, which may not use private API.
    static var isAvailable: Bool {
        ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] == nil && lockFunction != nil
    }

    /// Returns false when locking is unavailable.
    @discardableResult
    static func lock() -> Bool {
        guard isAvailable, let lockFunction else { return false }
        // The return value is undocumented; the lock notification confirms it.
        _ = lockFunction()
        return true
    }
}
