#!/usr/bin/env bash
set -u
ASSETS_DIR="${AMA_ASSETS_DIR:-$HOME/.config/ama/assets}"
VOICE_FILE="$ASSETS_DIR/audio/lets_coding.mp3"

# Optional coding sound; VS Code still opens if no audio player is installed.
if [[ -r "$VOICE_FILE" ]]; then
  if command -v mpg123 >/dev/null 2>&1; then mpg123 -q "$VOICE_FILE" >/dev/null 2>&1 &
  elif command -v ffplay >/dev/null 2>&1; then ffplay -nodisp -autoexit -loglevel quiet "$VOICE_FILE" >/dev/null 2>&1 &
  elif command -v paplay >/dev/null 2>&1; then paplay "$VOICE_FILE" >/dev/null 2>&1 &
  fi
fi
if [[ -x /snap/bin/code ]]; then exec /snap/bin/code "$@"; fi
if command -v code >/dev/null 2>&1; then exec "$(command -v code)" "$@"; fi
printf 'AMA: VS Code executable was not found.\n' >&2
exit 127
