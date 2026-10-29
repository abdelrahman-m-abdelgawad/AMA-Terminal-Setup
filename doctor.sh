#!/usr/bin/env bash
set -u
for cmd in zsh git python3 starship kitty eza fzf zoxide atuin lazygit delta tmux fastfetch btop yazi; do
  if command -v "$cmd" >/dev/null 2>&1; then printf '[OK] %s -> %s\n' "$cmd" "$(command -v "$cmd")"; else printf '[MISSING] %s\n' "$cmd"; fi
done
for f in "$HOME/.config/ama/assets/10_background_blueprint.png" "$HOME/.config/ama/scripts/welcome.sh" "$HOME/.config/ama/scripts/build_welcome.py" "$HOME/.config/ama/scripts/launch_kitty.sh" "$HOME/.config/ama/scripts/launch_vscode.sh" "$HOME/.config/ama/zsh/launchers.zsh" "$HOME/.config/fastfetch/config.jsonc"; do
  if [[ -s "$f" ]]; then printf '[OK] file -> %s\n' "$f"; else printf '[OPTIONAL/MISSING] %s\n' "$f"; fi
done
for cmd in mpg123 ffplay paplay aplay; do command -v "$cmd" >/dev/null 2>&1 && printf '[AUDIO] %s -> %s\n' "$cmd" "$(command -v "$cmd")"; done
