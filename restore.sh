#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "$0")" && pwd)"
LATEST="$(ls -1dt "$ROOT"/backups/* 2>/dev/null | head -n 1 || true)"
if [[ -z "$LATEST" ]]; then
  echo "No backups found."
  exit 1
fi

[[ -f "$LATEST/starship.toml" ]] && cp -a "$LATEST/starship.toml" "$HOME/.config/starship.toml"
[[ -f "$LATEST/.zshrc" ]] && cp -a "$LATEST/.zshrc" "$HOME/.zshrc"
[[ -d "$LATEST/ama" ]] && cp -a "$LATEST/ama" "$HOME/.config/"
[[ -f "$LATEST/tmux.conf" ]] && cp -a "$LATEST/tmux.conf" "$HOME/.tmux.conf"
[[ -f "$LATEST/kitty.conf" ]] && cp -a "$LATEST/kitty.conf" "$HOME/.config/kitty/kitty.conf"
[[ -f "$LATEST/btop.conf" ]] && cp -a "$LATEST/btop.conf" "$HOME/.config/btop/btop.conf"
[[ -f "$LATEST/lazygit-config.yml" ]] && cp -a "$LATEST/lazygit-config.yml" "$HOME/.config/lazygit/config.yml"

echo "Restored from: $LATEST"
