# Video Studio

**Todo tu estudio de video para Claude Code, en una skill.** 41 skills + 1 plugin para editar, recortar, subtitular y crear videos con código, instaladas con un solo comando y usadas desde una sola puerta: `/video-studio`.

🌐 **Web con ejemplos visuales:** https://TU_USUARIO.github.io/video-studio/

## Instalar

Solo necesitas [Git](https://git-scm.com/downloads).

**Windows** (PowerShell):

```powershell
irm https://raw.githubusercontent.com/TU_USUARIO/video-studio/main/install.ps1 | iex
```

**Mac / Linux** (Terminal):

```bash
curl -fsSL https://raw.githubusercontent.com/TU_USUARIO/video-studio/main/install.sh | bash
```

Después reinicia Claude Code y escribe `/video-studio`.

El instalador:

- descarga cada skill de **su repositorio original** (siempre la última versión) y la deja en `~/.claude/skills/`;
- **nunca borra nada**: si ya tenías una skill con el mismo nombre, la mueve a `~/.claude/skills-backup/<fecha>/`;
- instala el plugin `lemo-opuscar` si encuentra el comando `claude`; si no, te dice los dos comandos que tienes que escribir dentro de Claude Code.

Para actualizar, vuelve a ejecutar el mismo comando.

## Qué incluye

| Para… | Skills |
|---|---|
| **Elegir la herramienta por ti** | `video-studio` |
| **Editar un video que ya tienes** | `ffmpeg-skill`, `ghost-editor`, `claude-shorts`, `reel-export` |
| **Crear videos con código** | `launch-video`, `apple-launch-film`, `vox-explainer`, `title-sequence-3d`, `newsletter-promo`, `milestone-reveal`, `animated-chart`, `loop-cover`, `motion-effects`, `model-showdown`, `lemo-opuscar` (plugin) |
| **Explicadores de papel recortado** | `papercut-explainer`, `papercut-strategy`, `papercut-hook`, `papercut-script`, `papercut-storyboard`, `papercut-voice`, `papercut-build`, `papercut-qa`, `papercut-setup` |
| **Remotion (video en React)** | `remotion-best-practices`, `remotion-create`, `remotion-studio`, `remotion-render`, `remotion-captions`, `remotion-markup`, `remotion-maps`, `remotion-multimedia`, `remotion-interactivity`, `remotion-saas`, `remotion-docs`, `remotion-upgrade`, `remotion-license` |
| **Planificar antes de crear** | `brand-intake`, `motion-brief-writer`, `motion-prompt-writer`, `reference-to-motion` |

Algunas skills necesitan programas extra (FFmpeg, Python, Node). Cada una te lo pide la primera vez que la usas. Para papercut, di "set up papercut-explainer" dentro de Claude Code.

## Créditos

Este repo solo contiene la skill `/video-studio`, la web y el instalador. Todo lo demás se descarga de sus autores:

| Repo | Autor | Licencia |
|---|---|---|
| [charlie947/motion-graphics-skills](https://github.com/charlie947/motion-graphics-skills) | Charlie Hills | MIT |
| [remotion-dev/skills](https://github.com/remotion-dev/skills) | Remotion | [Licencia de Remotion](https://www.remotion.dev/license) |
| [0xS4N4TG/papercut-explainer](https://github.com/0xS4N4TG/papercut-explainer) | sanat | MIT |
| [kajisho5/ffmpeg-skill](https://github.com/kajisho5/ffmpeg-skill) | kajisho5 | MIT |
| [kurbaitaev/ghost-editor](https://github.com/kurbaitaev/ghost-editor) | kurbaitaev | MIT |
| [agricidaniel/claude-shorts](https://github.com/agricidaniel/claude-shorts) | Daniel Agrici | MIT |
| [lemomo-ai/lemo-opuscar](https://github.com/lemomo-ai/lemo-opuscar) | Lemomo | MIT |

## Licencia

MIT para lo que hay en este repo (la skill `video-studio`, la web y los instaladores). Cada skill descargada conserva la licencia de su autor.
