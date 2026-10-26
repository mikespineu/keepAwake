# Scenario template

Copy this into `marketing/<channel>/SCENARIO.md`. Existing examples: `marketing/linkedin/SCENARIO.md` (feature ad) and `marketing/slack/SCENARIO.md` (one-idea story clip).

```markdown
# keepAwake: <video name>

- **Format:** 1080×1350 (4:5), 30 fps, <length> s, H.264 MP4. Composition `<CompositionId>`.
- **Audience:** <who sees it, where, and what they already know>.
- **Sound:** <none / music suggestion>. Captions carry every beat.
- **Look:** <brand notes, hero visual>.
- **Story:** <problem → pain → product → how → features → CTA, or the one idea>.
- **Source:** `marketing/video/src/<Name>Ad.tsx`, scenes in `marketing/video/src/scenes/<video>/`.

| # | Time | Scene | Visuals and motion | On-screen text |
|---|---|---|---|---|
| 1 | 0.0–4.0 s | **Hook** (`Hook.tsx`) | <what moves, what changes> | **"<main caption>"** / "<secondary>" |
| … | | | | |

## Render

    cd marketing/video
    npm run render:<name>
    npm run thumbnail:<name>   # frame N: <why this frame>

## Claims check (keepAwake <version>)

- <claim> — <source file / changelog entry>.
- <what was deliberately left out and why>.
```

## Writing the rows

- **Time** is real seconds in the final cut, not the planned scene length. Scene start = sum of the previous scene lengths − 12 frames × (scenes before it), divided by 30.
- **Visuals**: describe motion and state changes, e.g. "the menu flips to *Active · held by Claude Code*", so whoever edits the code knows which state to show.
- **On-screen text**: exact caption text, with `→` between captions in the same scene and **bold** for the main line.
- Quote menu text exactly as `MenuView.swift` has it.
