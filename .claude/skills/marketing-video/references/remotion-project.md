# marketing/video: the Remotion project

## Layout

```
marketing/video/
├── package.json          # pinned: remotion / @remotion/cli / @remotion/transitions 4.0.533, react 19.2.0
├── remotion.config.ts    # jpeg 95, h264, crf 18, yuv420p, bt709, overwrite
├── public/icon.png       # copy of docs/icon.png (the app icon)
├── out/                  # rendered MP4s + thumbnails, committed on the marketing branch
└── src/
    ├── index.ts / Root.tsx    # registerRoot + one <Composition> per video
    ├── theme.ts               # brand tokens C, SANS, MONO, FPS, WIDTH, HEIGHT, TRANSITION, SCENES (LinkedIn ad)
    ├── Ad.tsx                 # LinkedIn ad: TransitionSeries over SCENES
    ├── LidClosedAd.tsx        # Slack clip: its own SCENES list + LID_TOTAL_FRAMES
    ├── components/
    │   ├── Common.tsx         # GridBackground, Enter (spring fade-up), useEnter, fadeOut, Headline, Caption
    │   ├── Glyphs.tsx         # Mug (line / filled), Cursor, Wifi, Battery, FeatureIcon(clock|agent|battery|lid|display|login)
    │   ├── MenuPanel.tsx      # the keepAwake menu, driven by a MenuState object
    │   ├── Desktop.tsx        # macOS wallpaper + menu bar + panel + cursor + camera
    │   ├── Demo.tsx           # cursorAt, isPressed, openAmount, statusCountdown, menuBarCountdown, CaptionBand
    │   └── Laptop.tsx         # CSS 3D MacBook, lid 0 (open) … 1 (closed), any React node on screen
    └── scenes/
        ├── Hook, Pain, Reveal, Timer, Agents, Features, Cta   # LinkedIn ad (Cta is shared)
        └── lid/Intro, Commute, LidMenu, Recap                 # Slack clip
```

## Adding a video

1. Create `src/<Name>Ad.tsx` modelled on `LidClosedAd.tsx`: a `SCENES: [name, frames, Component][]` list, an exported total (`sum − TRANSITION × (n − 1)`), and a `TransitionSeries` with `fade()`.
2. Register it in `Root.tsx` with `WIDTH`/`HEIGHT`/`FPS` from `theme.ts`, or new sizes if the format differs.
3. Add `render:<name>` and `thumbnail:<name>` scripts.
4. Scene components read `useCurrentFrame()`, which is local to their sequence and starts at 0.

## Brand

Tokens come from the website (`docs/index.html`): background `#0b0c0f` with a 48 px blue grid (`GridBackground`), surfaces `#15171c`, text `#f2f3f5`, muted `#a2a7b3`, accent `#4f8cff`, danger `#ff5f57`, ok `#3ddc84`. Fonts: the system SF Pro / SF Mono stacks (`SANS`, `MONO`), which render correctly because we render on macOS. Headlines are 64–92 px, weight 700–750, letter-spacing −0.025em.

## The macOS desktop (`Desktop.tsx`)

- Everything inside the desktop is laid out in **macOS points** and scaled by `DESKTOP_SCALE = 1.7`, so the menu keeps the app's real proportions (300 pt wide). Cursor positions, `MUG_TARGET`, `PANEL_LEFT`, `PANEL_TOP` and camera focus points are in points. Captions (`children`) are in frame pixels.
- `MenuPanel` uses fixed line heights, so control positions can be computed. Measured targets that work: the "1 h" preset is `{x: PANEL_LEFT + 243, y: 138}` (inactive state). "Connect: Claude Code" is `{x: PANEL_LEFT + 111, y: 375}` (inactive). "Keep awake with lid closed" is `{x: PANEL_LEFT + 110, y: 559}` (held by an agent, presets shown). Any state change above a control (active section, hold row) pushes it down, so re-measure from a still.
- `MenuState` mirrors the app: `activeText` set → the Turn Off section shows. `showPresets: false` only while your own timer runs. `hold` adds the "Name · until HH:MM" row. `glow` outlines `'hold' | 'connect' | 'lid'`. `lidHelperInstalled` swaps the admin-password hint for the bag warning.
- **Camera**: `{progress, zoom, focus (pt), target (px)}` moves the focus point to the target while zooming. The wallpaper is twice the frame height, so pans downwards are safe. Horizontally, keep `target.x ≥ zoom × focus.x × 1.7 + WIDTH × (1 − zoom)`, or a black strip shows on the right. To zoom into the menu bar, pin it to the top with `target.y = focus.y × 1.7 × zoom`.
- The menu bar label must use `menuBarCountdown()`, the same rounding as the app (`1:00` → `59:59`).

## Laptop (`Laptop.tsx`)

`<Laptop lid={0..1} screen={<YourScreen/>} />`. It is 760 px wide, the lid hinges at its bottom edge, and the base is tilted 18° so we look down at it. Put story cards above the laptop (y ≈ 400–650) while it's closed; the closed slab sits around y 900–1100 when the laptop's top is 560. Sway and bob it with a wrapper transform, not by changing the laptop itself.

## Pitfalls already hit

- **Never trust coordinates without looking.** Render, extract frames (`scripts/contact-sheet.sh`), read the image, and adjust. Cursor targets and camera framing were each wrong on the first try.
- Pin versions at least two weeks old; `npm view remotion time --json` lists release dates. `esbuild`'s postinstall is skipped by npm's allowScripts and that's fine: Remotion still bundles.
- Without `Config.setColorSpace('bt709')` the MP4 comes out as full-range `yuvj420p`, which looks washed out in some players.
- A one-off `Enter` delay longer than the scene means the element never appears. Check delays against the `SCENES` length.
- Emoji render through Apple Color Emoji on macOS. Keep them in copy, but don't rely on them for meaning.
- Re-rendering takes ~30 s per video. Re-render only the composition you changed, unless shared components changed visibly.
