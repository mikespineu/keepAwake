# Publishing keepAwake on the Mac App Store

## What's already in the repo

| Requirement | Where |
|---|---|
| App Sandbox entitlement | `Resources/keepAwake.entitlements` |
| Privacy manifest (UserDefaults, reason `CA92.1`; no tracking, no data collected) | `Resources/PrivacyInfo.xcprivacy` |
| App icon (all macOS sizes) | `Resources/Assets.xcassets/AppIcon.appiconset` |
| Category, encryption-export flag, version variables | `Resources/Info.plist` |
| Xcode project (universal arm64 + x86_64 when archived) | `keepAwake.xcodeproj`, generated from `project.yml` |
| Screenshots 2880×1800 (light and dark) | `docs/appstore/` |
| Privacy policy | [`PRIVACY.md`](PRIVACY.md) |

Sandbox behaviour was checked locally: power assertions, battery reading and the app container all work with the entitlement above.

The *Keep awake with lid closed* mode (1.1.0) needs `sudo`, which the sandbox blocks, so the store build hides that toggle. The website zip is built by `build.sh` without the sandbox and has it.

## Steps you need to do

1. **Install Xcode** from the Mac App Store, open it once, and accept the license. Then point the command line at it:

   ```bash
   sudo xcode-select -s /Applications/Xcode.app
   ```

2. **Join the Apple Developer Program** ($99/year) at https://developer.apple.com/programs/.

3. **Open the project** `keepAwake.xcodeproj`. After editing `project.yml`, regenerate it with `xcodegen generate` (`brew install xcodegen`).

4. **Signing:** select the *keepAwake* target → *Signing & Capabilities* → choose your Team. Automatic signing registers the bundle ID `com.michalkrecisz.keepAwake`. To make this permanent, set `DEVELOPMENT_TEAM` in `project.yml`.

5. **Create the app record** in [App Store Connect](https://appstoreconnect.apple.com) → *Apps* → *+* → *New App*:
   - Platform: macOS
   - Name: see below
   - Bundle ID: `com.michalkrecisz.keepAwake`
   - SKU: `keepawake-mac`

6. **Archive and upload:** in Xcode choose *Product → Archive*, then *Distribute App → App Store Connect → Upload*.

7. **Fill in the listing** with the metadata below, upload the screenshots from `docs/appstore/`, and answer the privacy questionnaire with **Data Not Collected**.

8. **Submit for review.**

### For every new version

Bump `MARKETING_VERSION` (e.g. 1.0.1) and **always** `CURRENT_PROJECT_VERSION` in `project.yml`, then run `xcodegen generate` and archive again.

## Listing metadata (draft)

**Name** (max 30): `keepAwake`
If that name is taken, use `keepAwake – Stay Awake` instead.

**Subtitle** (max 30): `Stop your Mac from sleeping`

**Promotional text** (max 170):
> Keep your Mac awake for 15 minutes, a few hours or always. One click in the menu bar, with automatic shut-off when your battery runs low.

**Description:**
> keepAwake is a tiny menu bar app that stops your Mac from going to sleep — exactly as long as you need.
>
> • Choose a duration every time: 15 min, 30 min, 1 h, 2 h, 4 h, a custom time of up to 30 days, or Always.
> • See the remaining time right in the menu bar.
> • Battery guard: keepAwake turns itself off when your battery drops below the level you choose (10% by default), so a forgotten timer never drains your laptop.
> • Optionally keep the display on too.
> • Launch at login if you like.
> • Get a notification when keepAwake stops on its own.
>
> No Dock icon, no accounts, no tracking, no internet access. Open source under the MIT license.

**Keywords** (max 100, comma-separated):
`caffeinate,awake,no sleep,prevent sleep,stay awake,insomnia,battery,timer,menu bar,display,screen`

**Category:** Utilities (primary), Productivity (secondary)

**Age rating:** 4+ (answer "None" to every question)

**Price:** your choice; Free is simplest.

**URLs**
- Support URL: https://github.com/mikespineu/keepAwake/issues
- Marketing URL: https://github.com/mikespineu/keepAwake
- Privacy Policy URL: https://github.com/mikespineu/keepAwake/blob/main/PRIVACY.md

**Copyright:** `2026 Michał Kręcisz`

**App Review notes:**
> keepAwake is a menu bar–only app (LSUIElement), so it has no Dock icon or main window. After launch, click the cup icon in the menu bar. Pick a duration (e.g. "15 min") to activate; the remaining time appears next to the icon. You can confirm it works with `pmset -g assertions` (a "keepAwake: user requested" assertion). "Launch at login" is off by default and only enabled when the user turns it on. Quit is available at the bottom of the menu.

## Review risks to keep in mind

- **Minimum functionality / similar apps (guidelines 4.2, 4.3):** the battery guard and the countdown in the menu bar make the app distinct. Mention them first.
- **Don't name competitors** (e.g. Amphetamine, Caffeine) in the keywords or description; Apple rejects that.
- **Screenshots must show the real app:** the ones in `docs/appstore/` are rendered from the app's actual SwiftUI views. Regenerate them after UI changes:

  ```bash
  swift build -c release
  BIN="$(swift build -c release --show-bin-path)"
  cp Resources/Assets.xcassets/MenuBarIcon*.imageset/*.png "$BIN/"   # menu bar images
  "$BIN/KeepAwake" --snapshot docs
  ```
