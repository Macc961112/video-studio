---
name: video-studio
description: Single entry point for every video skill installed (FFmpeg editing, talking-head reels, shorts from long videos, Remotion, papercut explainers, motion graphics, launch films, Vox explainers, 3D titles, animated charts, loop covers, reel export, OpenArt AI video). Use when the user says "video-studio", "estudio de video", "quiero hacer un video", "edita este video", "haz un reel", or asks for any video task and it is not obvious which skill fits. Picks the right skill and hands off to it.
---

# Video Studio

This skill is a router. It does no video work itself: it picks the right installed skill and loads it with the Skill tool, then follows that skill's instructions.

## How to work

1. If the request is unclear, ask ONE question: what do they have (a video file, a link, an idea, data) and what do they want out (reel, short, explainer, launch, chart, GIF).
2. Pick the skill from the table below. If two fit, say which one you chose in one line and why.
3. Call `Skill` with that exact name and follow it. Do not copy its steps here.
4. For a brand-styled piece with no `brand.md` / `MOTION.md` in the project, offer `brand-intake` first (one line, don't force it).

## Routing table

### The user has a video file to edit
| Want | Skill |
|---|---|
| Cut, trim, join, resize, subtitles, music, loudness, platform export, any FFmpeg job | `ffmpeg-skill` |
| Raw talking-head phone recording → finished vertical reel (best takes, captions, SFX, B-roll) | `ghost-editor` |
| Long video → several viral short clips | `claude-shorts` |
| Horizontal/square motion video → clean 1080x1920 Reel/TikTok | `reel-export` |

### The user wants a video made in code
| Want | Skill |
|---|---|
| 30-45 s product/SaaS launch | `launch-video` |
| Apple / Mac keynote style launch, notch animation | `apple-launch-film` |
| Vox-style documentary explainer (30-60 s) | `vox-explainer` |
| Vertical cut-paper explainer from a link | `papercut-explainer` |
| Cinematic 3D intro / title sequence | `title-sequence-3d` |
| Promo for a newsletter edition | `newsletter-promo` |
| Milestone number reveal (followers, revenue) | `milestone-reveal` |
| Animated chart / data graphic | `animated-chart` |
| Looping GIF from a cover or thumbnail | `loop-cover` |
| One of the 16 motion effects (chart morph, particle logo, kinetic type...) | `motion-effects` |
| Same brief to 3 AI models, side-by-side video | `model-showdown` |
| Film in an artistic style (oil, watercolor, ukiyo-e, satellite, teardown) | `lemo-opuscar:lemo-opuscar` |
| Generic Remotion video / anything else in React | `remotion-best-practices` (router for all `remotion-*` skills) |
| AI-generated video clip (text/image to video) | OpenArt MCP tools (`openart_generate_video`), not a skill |

### Papercut stages (only when the user asks for one stage)
`papercut-strategy` → `papercut-hook` → `papercut-script` → `papercut-storyboard` → `papercut-voice` → `papercut-build` → `papercut-qa`. Install/repair: `papercut-setup`.

### Remotion stages (only when the user asks for one)
`remotion-create`, `remotion-studio` (preview), `remotion-render` (export), `remotion-captions`, `remotion-markup`, `remotion-maps`, `remotion-multimedia`, `remotion-interactivity`, `remotion-saas`, `remotion-docs`, `remotion-upgrade`, `remotion-license`.

### Planning before building
| Want | Skill |
|---|---|
| Set up brand colours, type, motion rules | `brand-intake` |
| Rough idea → precise build brief | `motion-brief-writer` |
| Idea → 8-part Claude Motion prompt | `motion-prompt-writer` |
| "Make me something like this" from reference frames | `reference-to-motion` |

## Chaining
Common combos: `brand-intake` → any motion skill; any 16:9 motion skill → `reel-export` for vertical; `ghost-editor` or `claude-shorts` → `ffmpeg-skill` for final tweaks. Run them one after another, finishing each before loading the next.
