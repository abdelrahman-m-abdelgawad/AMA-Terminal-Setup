#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "$0")" && pwd)"
HOME_DIR="$HOME"
backup_dir="$HOME_DIR/.config/ama/backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup_dir"

copy_file() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [[ -f "$dst" ]]; then
    cp -a "$dst" "$backup_dir/$(basename "$dst").bak"
  fi
  cp -a "$src" "$dst"
}

copy_file "$ROOT/configs/starship/starship.toml" "$HOME_DIR/.config/starship.toml"
copy_file "$ROOT/configs/zsh/ama.zsh" "$HOME_DIR/.config/ama/zsh/ama.zsh"
copy_file "$ROOT/configs/zsh/paths.zsh" "$HOME_DIR/.config/ama/zsh/paths.zsh"
copy_file "$ROOT/configs/kitty/kitty.conf" "$HOME_DIR/.config/kitty/kitty.conf"
copy_file "$ROOT/configs/tmux/tmux.conf" "$HOME_DIR/.tmux.conf"
copy_file "$ROOT/configs/btop/btop.conf" "$HOME_DIR/.config/btop/btop.conf"
copy_file "$ROOT/configs/lazygit/config.yml" "$HOME_DIR/.config/lazygit/config.yml"

zshrc="$HOME_DIR/.zshrc"
if [[ -f "$zshrc" ]]; then
  grep -q 'source "$HOME/.config/ama/zsh/ama.zsh"' "$zshrc" || printf '\n[[ -r "$HOME/.config/ama/zsh/ama.zsh" ]] && source "$HOME/.config/ama/zsh/ama.zsh"\n' >> "$zshrc"
  grep -q 'starship init zsh' "$zshrc" || printf '\nif command -v starship >/dev/null 2>&1; then\n  eval "$(starship init zsh)"\nfi\n' >> "$zshrc"
fi

printf 'Installed AMA Terminal setup. Backup dir: %s\n' "$backup_dir"
printf 'Reload with: source ~/.zshrc\n'
