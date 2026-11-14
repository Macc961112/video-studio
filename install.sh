#!/usr/bin/env bash
# Video Studio: instala todas las skills de video para Claude Code (macOS / Linux).
# Uso:  curl -fsSL https://raw.githubusercontent.com/Macc961112/video-studio/main/install.sh | bash
set -euo pipefail

REPO="Macc961112/video-studio"
DEST="$HOME/.claude/skills"
BACKUP="$HOME/.claude/skills-backup/$(date +%Y%m%d-%H%M%S)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Repos que traen varias skills dentro de una carpeta skills/
PACKS=("$REPO" charlie947/motion-graphics-skills remotion-dev/skills 0xS4N4TG/papercut-explainer)
# Repos que son una sola skill (nombre=repo; se instalan enteros para poder hacer git pull)
SINGLES=(ffmpeg-skill=kajisho5/ffmpeg-skill ghost-editor=kurbaitaev/ghost-editor claude-shorts=agricidaniel/claude-shorts)

command -v git >/dev/null || { echo "Necesitas Git: https://git-scm.com/downloads" >&2; exit 1; }

get_repo() { git clone -q --depth 1 "https://github.com/$1.git" "$2" || { echo "No se pudo descargar $1" >&2; exit 1; }; }

# Nunca borra: si la skill ya existe, la mueve a la copia de seguridad.
set_skill() {
  if [ -e "$DEST/$2" ]; then mkdir -p "$BACKUP"; mv "$DEST/$2" "$BACKUP/$2"; fi
  mv "$1" "$DEST/$2"
  echo "  + $2"
}

mkdir -p "$DEST"
count=0
printf '\nVideo Studio: instalando skills en %s\n\n' "$DEST"
i=0
for r in "${PACKS[@]}"; do
  i=$((i + 1)); echo "Descargando $r ..."
  get_repo "$r" "$TMP/p$i"
  for s in "$TMP/p$i"/skills/*/; do set_skill "${s%/}" "$(basename "$s")"; count=$((count + 1)); done
done
for pair in "${SINGLES[@]}"; do
  name="${pair%%=*}"; r="${pair#*=}"; echo "Descargando $r ..."
  get_repo "$r" "$TMP/$name"
  set_skill "$TMP/$name" "$name"; count=$((count + 1))
done

# lemo-opuscar es un plugin, no una skill suelta.
plugin=0
if command -v claude >/dev/null; then
  claude plugin marketplace add lemomo-ai/lemo-opuscar && claude plugin install lemo-opuscar@lemolab && plugin=1 || true
fi

printf '\nListo: %s skills instaladas.\n' "$count"
[ -d "$BACKUP" ] && echo "Las versiones anteriores se guardaron en $BACKUP"
if [ "$plugin" = 0 ]; then
  printf '\nPara el plugin lemo-opuscar, escribe esto dentro de Claude Code:\n'
  echo '  /plugin marketplace add lemomo-ai/lemo-opuscar'
  echo '  /plugin install lemo-opuscar@lemolab'
fi
printf '\nReinicia Claude Code y escribe /video-studio para empezar.\n'
echo 'Algunas skills necesitan programas extra (FFmpeg, Python, Node). Cada una te lo pedira la primera vez.'
