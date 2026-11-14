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

printf '\n%s skills instaladas.\n' "$count"

# ---------- Librerias y dependencias basicas (las voces se instalan al usarlas) ----------
printf '\nInstalando librerias y dependencias. Puede tardar 10-20 minutos...\n\n'
FAILS=()
export PLAYWRIGHT_DOWNLOAD_CONNECTION_TIMEOUT=600000  # el navegador de render pesa ~100 MB
# Un paso que falla se apunta y se sigue con el siguiente.
step() { local n="$1"; shift; echo "> $n"; "$@" || { echo "  ! fallo: $n"; FAILS+=("$n"); }; }
have() { command -v "$1" >/dev/null; }
MISSING=""
for t in python3 node npm ffmpeg; do have "$t" || MISSING="$MISSING $t"; done
[ -n "$MISSING" ] && echo "Faltan programas:$MISSING. Los pasos que los necesitan se saltaran."

PAPER="$HOME/papercut-explainer"
step "lemo-opuscar: libreria de estilos" sh "$DEST/lemo-opuscar/scripts/setup.sh"
if [ -d "$PAPER/.git" ]; then step "papercut: actualizar libreria" git -C "$PAPER" pull -q --ff-only
else step "papercut: libreria" git clone -q --depth 1 https://github.com/0xS4N4TG/papercut-explainer.git "$PAPER"; fi
if have node && have npm && have python3; then
  step "lemo-opuscar: dependencias" sh "$DEST/lemo-opuscar/scripts/setup.sh" deps
  step "papercut: instalacion estandar" bash -c 'cd "$1" && ./install.sh --mode standard --yes --target claude' _ "$PAPER"
  step "claude-shorts: Python y Remotion" bash "$DEST/claude-shorts/setup.sh"
fi
if have python3; then
  step "ghost-editor: paquetes Python" python3 -m pip install --user --quiet --no-warn-script-location openai-whisper numpy opencv-python pillow
  step "ghost-editor: sonidos y musica" python3 "$DEST/ghost-editor/scripts/library_restore.py"
fi

printf '\nListo.\n'
[ -d "$BACKUP" ] && echo "Las versiones anteriores de las skills se guardaron en $BACKUP"
if [ ${#FAILS[@]} -gt 0 ] || [ -n "$MISSING" ]; then
  echo "Pendiente:"
  [ -n "$MISSING" ] && echo "  - instala:$MISSING y vuelve a ejecutar este comando"
  for f in ${FAILS[@]+"${FAILS[@]}"}; do echo "  - $f (la skill lo reintentara la primera vez que la uses)"; done
fi
printf '\nReinicia Claude Code y escribe /video-studio para empezar.\n'
