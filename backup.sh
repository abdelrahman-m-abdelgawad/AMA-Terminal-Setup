#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "$0")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$ROOT/backups/$STAMP"
mkdir -p "$OUT"

cp -a "$HOME/.zshrc" "$OUT/.zshrc" 2>/dev/null || true
cp -a "$HOME/.config/starship.toml" "$OUT/starship.toml" 2>/dev/null || true
cp -a "$HOME/.config/ama" "$OUT/ama" 2>/dev/null || true
cp -a "$HOME/.tmux.conf" "$OUT/tmux.conf" 2>/dev/null || true
cp -a "$HOME/.config/kitty/kitty.conf" "$OUT/kitty.conf" 2>/dev/null || true
cp -a "$HOME/.config/btop/btop.conf" "$OUT/btop.conf" 2>/dev/null || true
cp -a "$HOME/.config/lazygit/config.yml" "$OUT/lazygit-config.yml" 2>/dev/null || true

echo "Backup created at: $OUT"
