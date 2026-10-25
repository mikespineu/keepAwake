# keepAwake

A tiny macOS menu bar app that keeps your Mac from going to sleep — for a set time, forever, or until the battery runs low.

**[⬇ Download for Mac](https://github.com/mikespineu/keepAwake/releases/latest/download/keepAwake.zip)** (macOS 14+, Apple Silicon & Intel) · [Website with install guide](https://mikespineu.github.io/keepAwake/)

Unzip, drag `keepAwake.app` to Applications and open it. The first launch needs one permission step, see [First launch](#first-launch-allow-keepawake-in-privacy--security).

## First launch: allow keepAwake in Privacy & Security

keepAwake is from an independent developer and isn't notarized by Apple, so the first time you open a downloaded copy macOS blocks it. This is expected; you give it permission once.

<img src="docs/gatekeeper-not-opened.png" alt="macOS dialog: “keepAwake” Not Opened" width="270" align="right">

1. Double-click keepAwake in Applications. macOS shows **“keepAwake” Not Opened**. Click **Done**, not *Move to Trash*.
2. Open **Apple menu → System Settings → Privacy & Security**.
3. Scroll down to **Security**. Next to *“keepAwake” was blocked to protect your Mac*, click **Open Anyway**.
4. Enter your password or use Touch ID.
5. macOS asks once more. Click **Open Anyway**. The mug appears in the menu bar.

**No “Open Anyway” button?** It only shows up for about an hour after macOS blocked the app. Open keepAwake again, click **Done**, and go back to Privacy & Security.

You don't need to change *“Allow applications from”* or disable any protection: **Open Anyway** allows only keepAwake. You'll repeat this after downloading an update.

Prefer Terminal? Instead of steps 1–5, remove the download quarantine flag, then open the app normally:

```bash
xattr -dr com.apple.quarantine /Applications/keepAwake.app
```

Apps you build yourself with `./build.sh` are not quarantined and open without this step.

<br clear="right">

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

- **Pick a duration every time you turn it on:** 15 min, 30 min, 1 h, 2 h, 4 h, a custom days + hours + minutes value (up to 30 days), or **Always**.
- **Countdown in the menu bar** next to the mug icon.
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

## Publishing a release

1. Bump `MARKETING_VERSION` (and `CURRENT_PROJECT_VERSION`) in `project.yml`.
2. Commit and push.
3. Run the release script:

   ```bash
   ./release.sh
   ```

The script builds a universal app (`./build.sh --universal`), packs it as `keepAwake.zip` and creates the GitHub Release `v<version>`. Use `./release.sh --dry-run` to only build the zip.

The website in `docs/index.html` is served by GitHub Pages from the `docs/` folder and always links to the latest release.

## Regenerating the screenshots and icon

The images in `docs/` (README) and `docs/appstore/` (App Store, 2880×1800) are rendered from the app's real SwiftUI views:

```bash
swift build -c release
BIN="$(swift build -c release --show-bin-path)"
cp Resources/Assets.xcassets/MenuBarIcon*.imageset/*.png "$BIN/"   # menu bar images
"$BIN/KeepAwake" --snapshot docs
```

The app icon is generated by `scripts/generate-icon.swift`:

```bash
swift scripts/generate-icon.swift
```

## Mac App Store

The project is prepared for the Mac App Store: App Sandbox, privacy manifest, icon, and an Xcode project (`keepAwake.xcodeproj`, generated from `project.yml` with [XcodeGen](https://github.com/yonaskolb/XcodeGen)). See [APPSTORE.md](APPSTORE.md) for the submission steps and listing metadata, and [PRIVACY.md](PRIVACY.md) for the privacy policy.

Local builds from `build.sh` are signed with the same sandbox entitlement, so they behave like the store version.

## License

[MIT](LICENSE)
