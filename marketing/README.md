# keepAwake marketing

Marketing copy, video scenarios and the Remotion project that renders the videos.

> **This folder lives only on the `marketing` branch.** Its pull request stays open as a draft and is never merged into `main`. To pick up new app features or screenshots, merge `main` into `marketing`, never the other way round.

| Piece | Copy | Scenario | Video |
|---|---|---|---|
| LinkedIn ad (feed + Sponsored Content) | [linkedin/POST.md](linkedin/POST.md) | [linkedin/SCENARIO.md](linkedin/SCENARIO.md) | `video/out/keepawake-linkedin.mp4` |
| Slack clip "close the lid, agents keep working" | [slack/POST.md](slack/POST.md) | [slack/SCENARIO.md](slack/SCENARIO.md) | `video/out/keepawake-lid-closed.mp4` |

## Video project

`video/` is one Remotion project with one composition per video, sharing brand tokens, the rebuilt keepAwake menu, the macOS desktop, the 3D laptop and the CTA scene.

```bash
cd marketing/video
npm install
npm run dev          # Remotion Studio
npm run render       # LinkedIn ad
npm run render:lid   # Slack clip
```

Rendered videos and thumbnails in `video/out/` are committed on this branch, so they can be shared straight from GitHub.

To write a new scenario or video, ask Claude Code. The project skill `.claude/skills/marketing-video` holds the workflow, the brand rules and the claims check.
