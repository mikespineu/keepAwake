# keepAwake: "lid closed" video scenario (Slack clip)

- **Format:** 1080×1350 (4:5), 30 fps, 29.0 s, H.264 MP4 (3 MB). Composition `KeepAwakeLidClosed`.
- **Audience:** friends and colleagues on Slack who already use coding agents. Casual tone, one idea: *close the lid, the agents keep working*.
- **Sound:** not needed; Slack autoplays muted. Captions carry the story.
- **Look:** same brand as the LinkedIn ad (dark grid, accent `#4f8cff`, SF Pro / SF Mono). The hero is a MacBook drawn in CSS 3D (`marketing/video/src/components/Laptop.tsx`) so the lid can actually close and open.
- **Source:** `marketing/video/src/LidClosedAd.tsx` (scene list and lengths) and `marketing/video/src/scenes/lid/*.tsx`. The CTA reuses `scenes/Cta.tsx` from the LinkedIn ad. Scenes cross-fade over 12 frames.

| # | Time | Scene | Visuals and motion | On-screen text |
|---|---|---|---|---|
| 1 | 0.0–2.8 s | **Intro** (`Intro.tsx`) | Text on the dark grid with a soft blue glow. | **"Nobody knew they needed this."** / "Including me. 😅" |
| 2 | 2.4–15.4 s | **Commute** (`Commute.tsx`) | Open laptop, Claude Code terminal running tests. The lid closes (CSS 3D hinge). The closed laptop sways and bobs as if carried, with a floor shadow. A keepAwake card floats above it: *Active · held by Claude Code*, "Lid closed · Mac still awake", a test counter and a "Meeting · N min" chip ticking up. At 1,204/1,204 the card flips to *Inactive*, "Claude Code finished, so the Mac goes to sleep". The laptop stops, the lid opens on "✓ All 1,204 tests passed. Done." | "Claude Code is mid-refactor. / You're late for a meeting." → "Close the lid. / Laptop under your arm." → **"Your agents keep working."** → "Done? / Now the Mac can sleep." → **"Back at your desk: the work is done."** |
| 3 | 15.0–21.3 s | **Menu** (`LidMenu.tsx`) | The real 1.2.0 menu held by Claude Code (hold row glowing). The camera pans down to the options; the cursor turns on **Keep awake with lid closed**, which glows and shows the app's own warning "Don't put a running Mac in a bag — it can overheat." | "Connect Claude Code, / then flip one switch." → **"Keep awake with lid closed."** / "No external display needed." |
| 4 | 20.9–24.9 s | **Recap** (`Recap.tsx`) | Four feature rows slide in. | **"One tiny menu bar app."** · Claude Code & Cursor · Lid closed · Timer · Battery guard |
| 5 | 24.5–29.0 s | **CTA** (`Cta.tsx`, shared) | Icon, name, pulsing Download button, URL. | "keepAwake for Mac" / "Free & open source" / [Download free] / `mikespineu.github.io/keepAwake` |

## Render

```bash
cd marketing/video
npm run render:lid      # out/keepawake-lid-closed.mp4
npm run thumbnail:lid   # out/thumbnail-lid-closed.png (frame 260: card says "keep working")
```

## Claims check (keepAwake 1.2.0)

- Lid-closed mode keeps the Mac running with the lid shut, even without an external display. It is off by default and asks for the admin password once (`CHANGELOG.md` 1.1.0).
- It applies to agent holds too, and when keepAwake stops with the lid closed the Mac goes to sleep, which is why the card says "the Mac goes to sleep" when Claude Code finishes (`CHANGELOG.md` 1.2.0 "Changed").
- The toggle label and the warning text are copied from `MenuView.swift` (`lidSection`).
- The meeting clock is a time-lapse (38 min in ~4 s); nothing claims real-time behaviour.
