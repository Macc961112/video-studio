#!/usr/bin/env bash
# Video Studio: instala todas las skills de video para Claude Code (macOS / Linux).
# Uso:  curl -fsSL https://raw.githubusercontent.com/Macc961112/video-studio/main/install.sh | bash
set -euo pipefail

REPO="Macc961112/video-studio"
DEST="$HOME/.claude/skills"
BACKUP="$HOME/.claude/skills-backup/$(date +%Y%m%d-%H%M%S)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Repos que traen varias skills (repo=carpeta donde estan; solo se descarga esa carpeta)
PACKS=("$REPO=skills" charlie947/motion-graphics-skills=skills remotion-dev/skills=skills 0xS4N4TG/papercut-explainer=skills lemomo-ai/lemo-opuscar=plugin/skills)
# Repos que son una sola skill (nombre=repo; se instalan enteros para poder hacer git pull)
SINGLES=(ffmpeg-skill=kajisho5/ffmpeg-skill ghost-editor=kurbaitaev/ghost-editor claude-shorts=agricidaniel/claude-shorts)

command -v git >/dev/null || { echo "Necesitas Git: https://git-scm.com/downloads" >&2; exit 1; }

get_repo() {
  if [ -n "${3:-}" ]; then
    git clone -q --depth 1 --filter=blob:none --sparse "https://github.com/$1.git" "$2" && git -C "$2" sparse-checkout set "$3"
  else
    git clone -q --depth 1 "https://github.com/$1.git" "$2"
  fi || { echo "No se pudo descargar $1" >&2; exit 1; }
}

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
for pair in "${PACKS[@]}"; do
  r="${pair%%=*}"; sub="${pair#*=}"
  i=$((i + 1)); echo "Descargando $r ..."
  get_repo "$r" "$TMP/p$i" "$sub"
  for s in "$TMP/p$i/$sub"/*/; do set_skill "${s%/}" "$(basename "$s")"; count=$((count + 1)); done
done
for pair in "${SINGLES[@]}"; do
  name="${pair%%=*}"; r="${pair#*=}"; echo "Descargando $r ..."
  get_repo "$r" "$TMP/$name"
  set_skill "$TMP/$name" "$name"; count=$((count + 1))
done

printf '\nListo: %s skills instaladas.\n' "$count"
[ -d "$BACKUP" ] && echo "Las versiones anteriores se guardaron en $BACKUP"
printf '\nReinicia Claude Code y escribe /video-studio para empezar.\n'
echo 'Algunas skills necesitan programas extra (FFmpeg, Python, Node). Cada una te lo pedira la primera vez.'
