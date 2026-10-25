# Changelog

All notable changes to keepAwake. Download any version from [GitHub Releases](https://github.com/mikespineu/keepAwake/releases).

## 1.2.0 — 2026-10-25

### Added

- **AI agents can keep your Mac awake while they work.** Claude Code, Cursor and any MCP client can hold keepAwake for as long as they're working, and let the Mac sleep when they finish. The menu shows who is holding it, with a button to end each hold.
- **Connect Claude Code / Cursor** buttons in the menu, or `KeepAwake install claude-code|cursor` in Terminal. They add keepAwake's hooks and MCP server to `~/.claude/settings.json`, `~/.cursor/hooks.json` and `~/.cursor/mcp.json`, keeping everything else in those files. The first change to each file saves a `.keepawake-backup` copy.
- **Hooks** hold the Mac awake for 30 minutes from each prompt and tool call, and release it when the agent stops or the session ends. If the agent crashes or is killed, its hold ends within a second.
- **MCP server** (`KeepAwake mcp`) with the tools `keep_awake` (1–1440 minutes, 60 by default), `allow_sleep` and `keep_awake_status`. A hold ends when its session ends.
- **`keepawake://` URL scheme** for scripts and Shortcuts: `start`, `stop`, `hold` and `release`.
- **Command line**: `KeepAwake hold|release|start|stop|status`, from `/Applications/keepAwake.app/Contents/MacOS/KeepAwake`.
- **Let AI agents keep your Mac awake** switch in the menu, on by default. Turning it off ends every hold and ignores agents until you turn it back on.

### Changed

- **Turn Off** ends agent holds too. When your own timer runs out, agent holds keep going.
- The battery guard and *Keep awake with lid closed* apply to agent holds the same way as to your own timer.

### Uninstall note

Before you delete the app, run `/Applications/keepAwake.app/Contents/MacOS/KeepAwake uninstall claude-code` and `… uninstall cursor` to remove the hooks and MCP server.

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
