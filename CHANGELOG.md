# Changelog

All notable changes to keepAwake. Download any version from [GitHub Releases](https://github.com/mikespineu/keepAwake/releases).

## 1.1.0 — 2026-10-25

### Added

- **Keep awake with lid closed** (optional, in the menu): the Mac keeps running with the lid shut, even without an external display. Turning it on the first time asks for your admin password once, to install a one-line sudoers rule that only allows `pmset -a disablesleep 1` and `pmset -a disablesleep 0`.
- The override is undone on every exit: Turn Off, the timer, the battery guard, Quit, a crash (within a few seconds) and the next launch after a reboot. If the lid is closed when keepAwake stops, the Mac goes to sleep.
- A sound when the time is up, even with notifications turned off.

### Changed

- The download is built without the App Sandbox, which the lid-closed mode needs. Settings from 1.0.0 are not carried over: set your battery limit and options again once.

### Uninstall note

If you used *Keep awake with lid closed*, remove the rule with `sudo rm -f /etc/sudoers.d/keepawake`.

## 1.0.0 — 2026-10-25

First release.

- Keep the Mac awake for 15 min, 30 min, 1 h, 2 h, 4 h, a custom time of up to 30 days, or always.
- Countdown in the menu bar.
- Battery guard: turns itself off below a battery level you choose (10% by default).
- Keep display on, launch at login, notification when keepAwake stops on its own.
- Universal build for Apple Silicon and Intel, macOS 14 or newer.
