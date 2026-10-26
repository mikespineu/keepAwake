---
name: release
description: Checklist for shipping a new keepAwake version — every file that must change (version numbers, Xcode project, CHANGELOG.md, website, README, screenshots), the PR, and publishing the GitHub Release with release.sh. Use this whenever the user asks to prepare, cut, bump, tag or publish a release or a new version (e.g. "release 1.3.0", "przygotuj release", "bump the version"), or to update the changelog or the website's "What's new" for a version, even if they don't say "release.sh".
---

# Releasing keepAwake

A release is one PR to `main` that carries the feature, the version bump and every user-facing text, followed by `./release.sh` on `main` once that PR is merged. The website (`docs/`, GitHub Pages from `main`) and the download link (`releases/latest/download/keepAwake.zip`) update by themselves after that.

## 0. Version number and branch

- Look up the last release first: `gh release list --limit 3` and the top of `CHANGELOG.md`. Never skip a number (no 1.3.1 without a 1.3.0).
- Semver: bug fixes and small additions bump the patch (1.2.0 → 1.2.1), a bigger feature bumps the minor (1.2.0 → 1.3.0). If the user names a number that skips one or doesn't fit, ask before using it.
- Work on a branch from `origin/main` (`feature/<name>`), never on `marketing` (that branch is never merged into `main`).

## 1. Files to change

| File | What to change |
|---|---|
| `project.yml` | `MARKETING_VERSION` to the new version. `CURRENT_PROJECT_VERSION` **+1 on every release**, even a patch: the App Store rejects a repeated build number. `build.sh` and `release.sh` read both from here. |
| `keepAwake.xcodeproj/project.pbxproj` | Run `xcodegen generate` after editing `project.yml` (never edit the pbxproj by hand; `brew install xcodegen`). Check that both configurations show the new numbers: `grep -n "MARKETING_VERSION\|CURRENT_PROJECT_VERSION" keepAwake.xcodeproj/project.pbxproj`. |
| `CHANGELOG.md` | New section at the top, exactly `## <version> — <YYYY-MM-DD>` (em dash). Subsections `### Added`, `### Changed`, `### Fixed`, `### Uninstall note` as needed. Bold lead phrase per bullet. `release.sh` uses this section as the release notes and stops if it is missing or the heading doesn't match. |
| `docs/index.html` | 1. Hero badge: `<span class="tag">New in <version></span> <one-line hook> →`. 2. *What's new*: a new `<div class="release">` at the **top** with `<span class="tag"><version></span> <Month D, YYYY>` and 2–4 short `<li>` bullets in plain language (not a copy of the changelog). 3. Move the `<p class="release-links">` (Full changelog · All releases) into the new block, so only the newest release has it. 4. Update the feature cards under *What it does* if the release adds something people should find there. |
| `README.md` | *Features*, *Usage* and *How it works* for anything user-visible or any new system API. *Mac App Store* section if something is hidden in the sandboxed build. |
| `docs/menu-*.png` | Only if the menu looks different. See step 2. |
| `APPSTORE.md`, `PRIVACY.md` | Only if the store listing or data handling changes (e.g. new permissions, network access). |

User-facing text must match the app: copy button and toggle labels verbatim from `Sources/KeepAwake/MenuView.swift`.

## 2. Screenshots

The images are rendered from the real SwiftUI views:

```bash
swift build -c release
BIN="$(swift build -c release --show-bin-path)"
cp Resources/Assets.xcassets/MenuBarIcon*.imageset/*.png "$BIN/"
"$BIN/KeepAwake" --snapshot docs
```

This rewrites every image, and the menu bar clock changes each time. Look at the new images and keep only the ones whose menu really changed. Restore the rest with `git checkout -- <file>`. The App Store images in `docs/appstore/` show the unsandboxed menu, so leave them alone when the change only appears outside the store build. If an image's size changed, update its `width`/`height` in `docs/index.html`.

## 3. Check

```bash
swift test
./release.sh --dry-run
```

The dry run builds the universal `build/keepAwake.zip` and prints the start of the release notes. Check that the notes are the new changelog section. Open `build/keepAwake.app` only if the installed copy in `/Applications` is quit first, so two copies don't fight over the `keepawake://` scheme and the status file.

## 4. PR

Commit with a message that names the feature and the version, push, and open a PR to `main`. In the PR description list the version, the user-facing changes and what was verified.

## 5. Publish (after the PR is merged)

Publishing is public and can't be undone quietly. **Ask the user before running it**, even if they asked for the release earlier.

```bash
git switch main && git pull
./release.sh
```

`release.sh` refuses to run with uncommitted changes, an unpushed `HEAD`, a missing changelog section or an existing tag. It creates the tag `v<version>` and the GitHub Release with `keepAwake.zip`.

Afterwards:

1. `gh release view v<version>`: the asset `keepAwake.zip` is attached and marked Latest.
2. The site https://mikespineu.github.io/keepAwake/ shows the new *What's new* (Pages can take a minute or two).
3. If the `marketing` branch should show the new feature, merge `main` into `marketing` (never the other way round).
