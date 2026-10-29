#!/usr/bin/env bash
set -euo pipefail

ASSETS_DIR="${AMA_ASSETS_DIR:-$HOME/.config/ama/assets}"
VOICE_DIR="$ASSETS_DIR/audio/kitty_voices"
STATE_DIR="$HOME/.cache/ama-robotics"
STATE_FILE="$STATE_DIR/kitty-last-voice"
mkdir -p "$STATE_DIR"

mapfile -d '' VOICES < <(find "$VOICE_DIR" -maxdepth 1 -type f \( -iname '*.wav' -o -iname '*.mp3' \) -print0 2>/dev/null | sort -z)
if ((${#VOICES[@]} > 0)); then
  LAST=""
  [[ -f "$STATE_FILE" ]] && IFS= read -r LAST < "$STATE_FILE" || true
  OPTIONS=()
  for voice in "${VOICES[@]}"; do [[ "$voice" == "$LAST" ]] || OPTIONS+=("$voice"); done
  ((${#OPTIONS[@]} > 0)) || OPTIONS=("${VOICES[@]}")
  SELECTED="${OPTIONS[$((RANDOM % ${#OPTIONS[@]}))]}"
  printf '%s\n' "$SELECTED" > "$STATE_FILE"
  case "${SELECTED,,}" in
    *.wav) if command -v aplay >/dev/null 2>&1; then aplay -q "$SELECTED" >/dev/null 2>&1 & fi ;;
    *.mp3)
      if command -v mpg123 >/dev/null 2>&1; then mpg123 -q "$SELECTED" >/dev/null 2>&1 &
      elif command -v ffplay >/dev/null 2>&1; then ffplay -nodisp -autoexit -loglevel quiet "$SELECTED" >/dev/null 2>&1 &
      elif command -v paplay >/dev/null 2>&1; then paplay "$SELECTED" >/dev/null 2>&1 &
      fi ;;
  esac
fi
KITTY_BIN="$(command -v kitty || true)"
if [[ -z "$KITTY_BIN" ]]; then echo "AMA: kitty was not found in PATH." >&2; exit 127; fi
exec "$KITTY_BIN" "$@"
