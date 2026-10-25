# keepAwake

A tiny macOS menu bar app that keeps your Mac from going to sleep — for a set time, forever, or until the battery runs low.

<table>
  <tr>
    <td align="center"><b>Inactive</b></td>
    <td align="center"><b>Active (countdown in the menu bar)</b></td>
  </tr>
  <tr>
    <td>
      <picture>
        <source media="(prefers-color-scheme: dark)" srcset="docs/menu-inactive-dark.png">
        <img src="docs/menu-inactive-light.png" alt="keepAwake menu while inactive" width="420">
      </picture>
    </td>
    <td>
      <picture>
        <source media="(prefers-color-scheme: dark)" srcset="docs/menu-active-dark.png">
        <img src="docs/menu-active-light.png" alt="keepAwake menu while active" width="420">
      </picture>
    </td>
  </tr>
</table>

## Features

- **Pick a duration every time you turn it on:** 15 min, 30 min, 1 h, 2 h, 4 h, a custom hours + minutes value, or **Always**.
- **Countdown in the menu bar** next to the cup icon.
- **Battery guard:** turns itself off when the battery drops below X% (on by default at 10%; only applies while running on battery).
- **Keep display on** (optional) — prevents the screen from dimming/sleeping too.
- **Launch at login** (optional).
- System notification when keepAwake stops by itself.
- No Dock icon, no background daemons, no root privileges.

## Requirements

- macOS 14 Sonoma or newer
- Xcode **Command Line Tools** (full Xcode is not required)

Install the Command Line Tools if you don't have them yet:

```bash
xcode-select --install
```

Check that Swift 6.0 or newer is available:

```bash
swift --version
```

## Build and install

1. Clone the repository:

   ```bash
   git clone https://github.com/mikespineu/keepAwake.git
   cd keepAwake
   ```

2. Build the app bundle:

   ```bash
   ./build.sh
   ```

   This compiles a release build and creates `build/keepAwake.app` (ad-hoc signed, for your Mac's architecture).

3. Install it to `/Applications` and launch it:

   ```bash
   ./build.sh --install
   ```

   A cup icon appears in the menu bar. Click it to start.

To update later, `git pull` and run `./build.sh --install` again — it quits the running copy and replaces it.

### Quick run without installing

```bash
swift run
```

Notifications and *Launch at login* don't work in this mode because the binary isn't inside an app bundle.

## Usage

1. Click the cup icon in the menu bar.
2. Choose how long to stay awake — a preset, a custom time (then **Start**), or **Always**.
3. Optionally set the battery threshold with the slider.
4. Click **Turn Off** to stop early.

Verify that the sleep assertion is active:

```bash
pmset -g assertions | grep keepAwake
```

## How it works

| Piece | Implementation |
|---|---|
| Menu bar UI | SwiftUI `MenuBarExtra` (window style), `LSUIElement` app |
| Preventing sleep | IOKit `IOPMAssertionCreateWithName` (`PreventUserIdleSystemSleep` / `PreventUserIdleDisplaySleep`) — the same mechanism `caffeinate` uses |
| Battery level | IOKit `IOPSCopyPowerSourcesInfo` + power-source change notifications (no polling) |
| Settings | `UserDefaults` |
| Launch at login | `SMAppService.mainApp` |

The assertion is released when you turn keepAwake off, when the timer or battery rule fires, or when the app quits.

## Limitations

- Closing the lid without an external display still puts the Mac to sleep — macOS doesn't allow blocking that without root privileges.
- `build.sh` builds only for the architecture of the Mac you build on. A universal (arm64 + x86_64) binary requires full Xcode.

## Uninstall

Quit keepAwake from its menu, then:

```bash
rm -rf /Applications/keepAwake.app
defaults delete com.michalkrecisz.keepAwake
```

## Regenerating the screenshots

The images in `docs/` are rendered from the app's real SwiftUI views:

```bash
swift build -c release
"$(swift build -c release --show-bin-path)/KeepAwake" --snapshot docs
```

## License

[MIT](LICENSE)
