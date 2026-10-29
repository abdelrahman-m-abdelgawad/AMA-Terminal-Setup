#!/usr/bin/env bash
set -euo pipefail

for cmd in zsh git python3 starship kitty eza fzf zoxide atuin lazygit delta tmux fastfetch btop yazi; do
  if command -v "$cmd" >/dev/null 2>&1; then
    printf '[OK] %s -> %s\n' "$cmd" "$(command -v "$cmd")"
  else
    printf '[MISSING] %s\n' "$cmd"
  fi
done
