import Foundation
import IOKit

struct CommandResult: Equatable, Sendable {
    var status: Int32
    var output: String
}

/// Runs external commands; replaced by a fake in tests.
protocol CommandRunner: Sendable {
    /// Runs the command to completion.
    func run(_ path: String, _ arguments: [String]) -> CommandResult
    /// Starts a process that outlives this app. Returns its pid.
    func launchDetached(_ path: String, _ arguments: [String]) -> Int32?
    func terminate(_ pid: Int32)
}

struct ProcessRunner: CommandRunner {
    func run(_ path: String, _ arguments: [String]) -> CommandResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
        } catch {
            return CommandResult(status: -1, output: error.localizedDescription)
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return CommandResult(status: process.terminationStatus, output: String(decoding: data, as: UTF8.self))
    }

    func launchDetached(_ path: String, _ arguments: [String]) -> Int32? {
        var attributes: posix_spawnattr_t?
        posix_spawnattr_init(&attributes)
        defer { posix_spawnattr_destroy(&attributes) }
        // Own process group, so a signal aimed at the app's group (e.g. Ctrl-C in a
        // terminal) does not take the watchdog down with it.
        posix_spawnattr_setflags(&attributes, Int16(POSIX_SPAWN_SETPGROUP))
        posix_spawnattr_setpgroup(&attributes, 0)

        let argv = ([path] + arguments).map { strdup($0) } + [nil]
        let envp = [strdup("PATH=/usr/bin:/bin:/usr/sbin:/sbin"), nil]
        defer { (argv + envp).forEach { free($0) } }

        var pid: pid_t = 0
        guard posix_spawn(&pid, path, nil, &attributes, argv, envp) == 0 else { return nil }
        return pid
    }

    func terminate(_ pid: Int32) {
        kill(pid, SIGTERM)
        waitpid(pid, nil, 0)
    }
}

enum Clamshell {
    /// True when the lid is closed and that would normally put the Mac to sleep
    /// (no external display in clamshell mode).
    static func closedAndCausesSleep() -> Bool {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPMrootDomain"))
        guard service != 0 else { return false }
        defer { IOObjectRelease(service) }

        func flag(_ key: String) -> Bool {
            IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?
                .takeRetainedValue() as? Bool ?? false
        }
        return flag("AppleClamshellState") && flag("AppleClamshellCausesSleep")
    }
}

/// Stops the Mac from sleeping when the lid closes, via `pmset -a disablesleep`.
/// That needs root, so a one-time install adds a sudoers rule that allows exactly
/// `pmset -a disablesleep 1` and `pmset -a disablesleep 0` without a password.
/// The setting survives the app, so a detached watchdog resets it if the app dies.
@MainActor
final class LidSleepOverride {
    static let sudoersPath = "/etc/sudoers.d/keepawake"

    /// `$1` is the app's pid. Once the app is gone: reset, and sleep if the lid is closed.
    static let watchdogScript = """
        while /bin/kill -0 "$1" 2>/dev/null; do /bin/sleep 5; done
        /usr/bin/sudo -n /usr/bin/pmset -a disablesleep 0
        /usr/sbin/ioreg -r -k AppleClamshellState -d 1 | /usr/bin/grep -q '"AppleClamshellCausesSleep" = Yes' && /usr/bin/pmset sleepnow
        """

    private let runner: CommandRunner
    private let fileExists: (String) -> Bool
    private let lidClosedCausesSleep: () -> Bool
    private let helperScriptPath: String?
    private let isSandboxed: Bool
    private let appPID: Int32
    private var watchdogPID: Int32?

    init(
        runner: CommandRunner = ProcessRunner(),
        fileExists: @escaping (String) -> Bool = { FileManager.default.fileExists(atPath: $0) },
        lidClosedCausesSleep: @escaping () -> Bool = Clamshell.closedAndCausesSleep,
        helperScriptPath: String? = Bundle.main.path(forResource: "lid-sleep-helper", ofType: "sh"),
        isSandboxed: Bool = ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] != nil,
        appPID: Int32 = getpid()
    ) {
        self.runner = runner
        self.fileExists = fileExists
        self.lidClosedCausesSleep = lidClosedCausesSleep
        self.helperScriptPath = helperScriptPath
        self.isSandboxed = isSandboxed
        self.appPID = appPID
    }

    /// False in the sandboxed (App Store) build, which cannot run sudo.
    var isAvailable: Bool { !isSandboxed && helperScriptPath != nil }

    var isInstalled: Bool { fileExists(Self.sudoersPath) }

    /// Returns false if sudo refused (helper not installed).
    func enable() -> Bool {
        guard setSleepDisabled(true) else { return false }
        if watchdogPID == nil {
            watchdogPID = runner.launchDetached(
                "/bin/sh", ["-c", Self.watchdogScript, "keepawake-watchdog", String(appPID)]
            )
        }
        return true
    }

    func disable() {
        setSleepDisabled(false)
        if let pid = watchdogPID {
            runner.terminate(pid)
            watchdogPID = nil
        }
        // With the override gone a closed lid does not put the Mac to sleep by itself.
        if lidClosedCausesSleep() {
            _ = runner.run("/usr/bin/pmset", ["sleepnow"])
        }
    }

    @discardableResult
    private func setSleepDisabled(_ disabled: Bool) -> Bool {
        runner.run("/usr/bin/sudo", ["-n", "/usr/bin/pmset", "-a", "disablesleep", disabled ? "1" : "0"]).status == 0
    }
}
