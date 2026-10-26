# keepAwake: LinkedIn video scenario

- **Format:** 1080×1350 (4:5 vertical, LinkedIn feed and video ads), 30 fps, 32.9 s, H.264 MP4 (3.4 MB).
- **Sound:** not needed. Most LinkedIn video autoplays muted, so captions carry every beat. If you add music, keep it calm (lo-fi) and quiet.
- **Look:** the keepAwake website brand: near-black background (`#0b0c0f`) with a faint blue grid, accent blue `#4f8cff`, SF Pro / SF Mono, the terminal-mug icon. Product shots are the 1.2.0 menu rebuilt in code (same labels, same countdown format as the app) on a purple-blue macOS wallpaper.
- **Story:** problem → pain → product → manual timer → AI agents → features → download.
- **Source:** `marketing/video/src/scenes/*.tsx` (shared scenes like `Cta.tsx` are reused by other videos), one file per scene. Scenes cross-fade over 12 frames (0.4 s).

| # | Time | Scene | Visuals and motion | On-screen text |
|---|---|---|---|---|
| 1 | 0.0–4.7 s | **Hook** | Terminal with a coding agent at work: a prompt, tool-call lines ticking, a test counter running. The screen dims to black (the Mac sleeps). "45 minutes later…" on black. The screen wakes: the counter is frozen at the same number and turns red. | "Your AI agent is refactoring." / "You go grab a coffee." → **"Your Mac fell asleep. Again."** |
| 2 | 4.3–7.8 s | **Pain** | Four task rows slide in. Each progress bar runs, stops and turns red with its failure label. | **"Mid-run. Mid-download. Mid-demo."** · `AI agent · refactor` paused mid-run · `macos-15.ipsw 13.4 GB` paused at 91 % · `Client demo · Zoom` screen went black · `ssh prod-db-01` connection dropped |
| 3 | 7.4–10.7 s | **Reveal** | The mug icon springs in with a blue glow. "keepAwake" types out after a `>` prompt with a blinking cursor. | **"keepAwake"** / "Keeps your Mac awake. Right from the menu bar." |
| 4 | 10.3–17.0 s | **Timer** | macOS desktop. The cursor clicks the mug, the menu drops down, the cursor clicks **1 h**. The menu switches to *Active · 1:00:00 (until 22:31)*, the status line counts down, and the menu bar label ticks `1:00 → 59:59 → 59:58`. | "Click the mug. Pick a time." → **"Countdown right in your menu bar."** |
| 5 | 16.6–24.2 s | **AI agents** | The cursor clicks **Connect: Claude Code**; the button gets a checkmark. A small agent terminal appears on the left and starts working. The menu flips to *Active · held by Claude Code*, "Kept awake by Claude Code.", and a hold row "Claude Code · until 22:13" with an ×. The agent prints "✓ All 1,204 tests passed", the hold disappears, the menu goes back to *Inactive*. | "Connect Claude Code or Cursor. One click." → **"Awake while your agent works."** → **"Asleep when it's done."** |
| 6 | 23.8–28.8 s | **Features** | Six tiles pop in on a 2×3 grid with line icons, then a mono line fades in. | **"Small app. Smart defaults."** · Any duration: 15 min to 30 days, or Always · AI agents: Claude Code, Cursor, any MCP client · Battery guard: turns off below 10 % · Lid closed: keeps running with the lid shut · Keep display on: no black screen mid-demo · Launch at login: set it once · `No Dock icon · CLI · keepawake:// URLs` |
| 7 | 28.4–32.9 s | **CTA** | Icon, name and a pulsing blue Download button. Lines fade in one after another. | **"keepAwake for Mac"** / "Free & open source" / [Download free] / `mikespineu.github.io/keepAwake` / "macOS 14+ · Apple Silicon & Intel" |

## Render

```bash
cd marketing/video
npm install
npm run dev        # Remotion Studio, scrub and tweak
npm run render     # out/keepawake-linkedin.mp4
npm run thumbnail  # out/thumbnail-linkedin.png
```

Scene lengths live in `marketing/video/src/theme.ts` (`SCENES`); the total updates itself.

## Thumbnail

A frame from the AI agents scene where the menu says *held by Claude Code*. Render it with `npm run thumbnail`.

## Claims check (keepAwake 1.2.0)

- Presets 15 min to 4 h, custom time up to 30 days, Always. Menu bar label is `H:MM` above one hour and `MM:SS` below, exactly as `KeepAwakeController.menuBarText`.
- Agent holds: hooks hold for 30 min from each prompt and tool call and release on stop, so "until 22:13" at 21:43 is accurate. Menu copy ("Active · held by Claude Code", "Kept awake by Claude Code.", "Claude Code · until 22:13", "Connect:") is taken from `MenuView.swift`.
- Battery guard 10 % by default, lid-closed mode (asks for the admin password once), Keep display on, Launch at login, no Dock icon, no daemons, CLI and URL scheme, macOS 14+, universal build.
- "No root" is **not** claimed: the optional lid-closed mode installs a sudoers rule.

## Variations to try later

- **1:1 square (1080×1080):** add a second `<Composition>` in `marketing/video/src/Root.tsx` and lower `DESKTOP_SCALE` in `marketing/video/src/components/Desktop.tsx`.
- **6-second bumper:** scene 5 only, then the CTA.
- **Dev-only cut:** drop scene 4 and open straight on the agent terminal.
