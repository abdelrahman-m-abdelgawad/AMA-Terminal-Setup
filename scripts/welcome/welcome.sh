#!/usr/bin/env bash
set -u
OVERLAY="$HOME/.config/ama/generated/welcome-overlay.png"
BUILDER="$HOME/.config/ama/scripts/build_welcome.py"
ASSETS="$HOME/.config/ama/assets"

# This intro is specifically for Kitty. Other terminals still work normally.
if [[ -z "${KITTY_WINDOW_ID:-}" || ! -t 1 ]]; then exit 0; fi

# Refresh dynamic system values when Pillow is available; otherwise use the bundled overlay.
if command -v python3 >/dev/null 2>&1 && python3 -c 'from PIL import Image' >/dev/null 2>&1 && [[ -r "$BUILDER" ]]; then
  python3 "$BUILDER" --assets "$ASSETS" --output "$OVERLAY" >/dev/null 2>&1 || true
fi
[[ -s "$OVERLAY" ]] || exit 0
command -v kitty >/dev/null 2>&1 || exit 0

# `clear` clears the temporary graphics layer; Kitty's configured background image persists.
command clear >/dev/null 2>&1 || true
cols="$(tput cols 2>/dev/null || printf '120')"
lines="$(tput lines 2>/dev/null || printf '36')"
[[ "$cols" =~ ^[0-9]+$ ]] || cols=120
[[ "$lines" =~ ^[0-9]+$ ]] || lines=36
(( cols < 40 )) && cols=40
(( lines < 18 )) && lines=18

if kitty +kitten icat --detect-support >/dev/null 2>&1; then
  kitty +kitten icat --place "${cols}x${lines}@0x0" --z-index -1 "$OVERLAY" 2>/dev/null || exit 0
  # Place the live shell prompt in a reserved area at the lower-left, like the mockup.
  row=$(( lines - 9 ))
  (( row < 3 )) && row=3
printf '\033[%d;2H' "$((row-2))"
fi
