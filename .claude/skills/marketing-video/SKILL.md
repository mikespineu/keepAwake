---
name: marketing-video
description: Write marketing copy, video scenarios (storyboards) and Remotion videos for the keepAwake Mac app, and render them. Use this whenever the user asks for a keepAwake ad, promo or demo video, a LinkedIn / Slack / X / Product Hunt post, a video script or storyboard, a new scene or composition in marketing/video, a re-render of an existing video, or wants to show a new keepAwake feature to people, even if they don't say "Remotion" or "scenario". Also use it when working on the `marketing` branch.
---

# keepAwake marketing videos

The goal is short, honest, muted-friendly videos and posts that show what keepAwake really does. Everything lives in `marketing/` on the **`marketing` branch**.

## 0. Branch rules (read first)

The `marketing` branch is long-lived and is **never merged into `main`**. Its PR stays a draft labelled "do not merge". The reason: marketing assets (rendered MP4s, node project, copy) should not ship with the app source or bloat `main`.

- Before working: `git switch marketing`, then `git merge origin/main` to pull in new features, menu copy and screenshots. Merge `main` into `marketing`, never the other way.
- Commit and push to `marketing`. Never open a second PR to `main` for this work, never retarget the draft PR, and never merge it, even if someone asks to "merge the marketing PR". Ask whether they really mean `main` first.
- Rendered files in `marketing/video/out/` are committed on purpose, so they can be shared from GitHub. `node_modules/` is not.
- If the work is on another branch by mistake, move it to `marketing` before committing.

## 1. Collect the facts

Marketing must not promise what the app doesn't do. Before writing a line of copy:

1. Read `CHANGELOG.md` for the shipped version and what each version added.
2. Read the "Features" and "Use with AI agents" sections of `README.md`.
3. Copy UI text **verbatim** from `Sources/KeepAwake/MenuView.swift` (labels, captions, status lines). Copy number formats from `KeepAwakeController.swift` (`statusText`, `menuBarText`: `H:MM` above one hour, `MM:SS` below).
4. Look at the current screenshots in `docs/menu-*-dark.png`. If they look different from `marketing/video/src/components/MenuPanel.tsx`, update the panel first.
5. Write down anything you plan to claim that you could not find in those files, and leave it out.

Known traps: don't say "no root" (lid-closed mode installs a sudoers rule). Don't say "notarized". Don't advertise unmerged plans in `plans/`. Mark time-lapses as such (e.g. "45 minutes later…").

## 2. Write the scenario

Create `marketing/<channel>/SCENARIO.md` with the template in `references/scenario-template.md`. Keep these principles in mind:

- **Muted first.** LinkedIn and Slack autoplay without sound, so every beat must read from captions alone. Big text (≥ 56 px on a 1080-wide frame), one idea per caption, two lines max.
- **Story shape:** a relatable problem (hook within 1.5 s) → the pain → the product → how it works in the real UI → what else it does → the download CTA.
- **Length:** 25–35 s for ads, 6 s for a bumper. Format 1080×1350 (4:5) by default, since it suits both LinkedIn and Slack.
- Show the **real menu**, rebuilt from the Swift source, not invented UI.
- End the scenario file with a "Claims check" section mapping each claim to its source file.

Write the copy (post, ad fields, hashtags) next to it in `marketing/<channel>/POST.md`. For LinkedIn, keep the hook within the first ~210 characters, put the link in the first comment, and add an A/B variant.

## 3. Build the video

The project is `marketing/video` (Remotion 4, React 19, TypeScript, pinned versions). Read `references/remotion-project.md` before you touch it. It lists every reusable component, how coordinates work in the macOS desktop, and the pitfalls that already cost time.

In short:

- A new video = a new `src/<Name>Ad.tsx` with a `SCENES` list, a `<Composition>` in `src/Root.tsx`, and `render:<name>` / `thumbnail:<name>` scripts in `package.json`.
- New scenes go in `src/scenes/<video>/`. Reuse `Desktop`, `MenuPanel`, `Laptop`, `CaptionBand`, `Cta` and the theme tokens rather than restyling.
- Run `npx tsc --noEmit` after edits.

## 4. Render and check

```bash
cd marketing/video
npm install                   # first time only
npm run render:<name>         # or: npx remotion render <CompositionId> out/<file>.mp4
npm run thumbnail:<name>
```

Then **look at it**. Extract a contact sheet of the key moments and read the image:

```bash
.claude/skills/marketing-video/scripts/contact-sheet.sh marketing/video/out/<file>.mp4 <frame> <frame> <frame> <frame>
```

The sheet is saved as `/tmp/contact-sheet.png`, or as the path given in `$OUT`. Check for: black edges after camera moves, the cursor landing on the right control, text overlapping, captions readable on the wallpaper, and counters and timestamps matching the scenario. Fix, re-render, and look again. `ffprobe` should report `h264`, `yuv420p`, `bt709`, 1080×1350.

Rendering takes about 30 s per video on Apple Silicon.

## 5. Ship

1. Update the timings in the scenario table to the real cut (scene offsets = sum of the previous durations minus 12 frames per transition).
2. Update `marketing/README.md` if you added a video.
3. Commit the source, the docs and the `out/*.mp4` + thumbnail to `marketing`, then push. The draft PR updates itself.
4. Send the user the rendered MP4 and the copy ready to paste.
