#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "$0")" && pwd)"
HOME_DIR="$HOME"
BACKUP_DIR="$HOME_DIR/.config/ama/backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR" "$HOME_DIR/.config/ama/assets" "$HOME_DIR/.config/ama/scripts" "$HOME_DIR/.config/ama/zsh" "$HOME_DIR/.config/ama/generated"

backup_destination() {
  local dst="$1" rel
  [[ -e "$dst" || -L "$dst" ]] || return 0
  rel="${dst#"$HOME_DIR"/}"
  mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
  cp -a "$dst" "$BACKUP_DIR/$rel"
}
copy_file() {
  local src="$1" dst="$2"
  [[ -f "$src" ]] || { echo "WARNING: source missing, skipped: $src" >&2; return 0; }
  mkdir -p "$(dirname "$dst")"
  backup_destination "$dst"
  cp -a "$src" "$dst"
}
copy_tree_files() {
  local srcdir="$1" dstdir="$2" src rel
  [[ -d "$srcdir" ]] || return 0
  while IFS= read -r -d '' src; do
    rel="${src#"$srcdir"/}"
    copy_file "$src" "$dstdir/$rel"
  done < <(find "$srcdir" -type f -print0)
}

copy_file "$ROOT/configs/starship/starship.toml" "$HOME_DIR/.config/starship.toml"
copy_file "$ROOT/configs/zsh/ama.zsh" "$HOME_DIR/.config/ama/zsh/ama.zsh"
copy_file "$ROOT/configs/zsh/paths.zsh" "$HOME_DIR/.config/ama/zsh/paths.zsh"
copy_file "$ROOT/configs/zsh/launchers.zsh" "$HOME_DIR/.config/ama/zsh/launchers.zsh"
copy_file "$ROOT/configs/kitty/kitty.conf" "$HOME_DIR/.config/kitty/kitty.conf"
copy_file "$ROOT/configs/tmux/tmux.conf" "$HOME_DIR/.tmux.conf"
copy_file "$ROOT/configs/btop/btop.conf" "$HOME_DIR/.config/btop/btop.conf"
copy_file "$ROOT/configs/lazygit/config.yml" "$HOME_DIR/.config/lazygit/config.yml"
if [[ -s "$ROOT/configs/fastfetch/config.jsonc" ]]; then
  copy_file "$ROOT/configs/fastfetch/config.jsonc" "$HOME_DIR/.config/fastfetch/config.jsonc"
fi
copy_tree_files "$ROOT/assets/ama-robotics" "$HOME_DIR/.config/ama/assets"
copy_tree_files "$ROOT/assets/audio" "$HOME_DIR/.config/ama/assets/audio"
copy_tree_files "$ROOT/scripts/welcome" "$HOME_DIR/.config/ama/scripts"
copy_file "$ROOT/scripts/launchers/launch_kitty.sh" "$HOME_DIR/.config/ama/scripts/launch_kitty.sh"
copy_file "$ROOT/scripts/launchers/launch_vscode.sh" "$HOME_DIR/.config/ama/scripts/launch_vscode.sh"
chmod +x "$HOME_DIR/.config/ama/scripts/welcome.sh" "$HOME_DIR/.config/ama/scripts/build_welcome.py" "$HOME_DIR/.config/ama/scripts/launch_kitty.sh" "$HOME_DIR/.config/ama/scripts/launch_vscode.sh" 2>/dev/null || true

if [[ -s "$HOME_DIR/.config/ama/assets/09_kitty_icon.png" ]]; then
  copy_file "$HOME_DIR/.config/ama/assets/09_kitty_icon.png" "$HOME_DIR/.config/kitty/kitty.app.png"
fi

ZSHRC="$HOME_DIR/.zshrc"
[[ -f "$ZSHRC" ]] || touch "$ZSHRC"
if ! grep -Fq 'starship init zsh' "$ZSHRC"; then
  cat >> "$ZSHRC" <<'ZSHSTARSHIP'

# AMA Terminal Setup: Starship prompt
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi
ZSHSTARSHIP
fi
if ! grep -Fq '.config/ama/zsh/ama.zsh' "$ZSHRC"; then
  printf '\n[[ -r "$HOME/.config/ama/zsh/ama.zsh" ]] && source "$HOME/.config/ama/zsh/ama.zsh"\n' >> "$ZSHRC"
fi
# Load launchers last so legacy ~/.zshrc functions are safely overridden.
if ! grep -Fq '.config/ama/zsh/launchers.zsh' "$ZSHRC"; then
  printf '\n[[ -r "$HOME/.config/ama/zsh/launchers.zsh" ]] && source "$HOME/.config/ama/zsh/launchers.zsh"\n' >> "$ZSHRC"
fi
if ! grep -Fq '# AMA Terminal Setup: welcome screen' "$ZSHRC"; then
  cat >> "$ZSHRC" <<'ZSHWELCOME'

# AMA Terminal Setup: welcome screen
if [[ -o interactive && -n "${KITTY_WINDOW_ID:-}" && "${TERM:-}" == "xterm-kitty" && -z "${TMUX:-}" && -z "${AMA_WELCOME_SHOWN:-}" ]]; then
  export AMA_WELCOME_SHOWN=1
  "$HOME/.config/ama/scripts/welcome.sh" || true
fi
ZSHWELCOME
fi

if python3 -c 'from PIL import Image' >/dev/null 2>&1 && [[ -f "$HOME_DIR/.config/ama/scripts/build_welcome.py" ]]; then
  python3 "$HOME_DIR/.config/ama/scripts/build_welcome.py" --assets "$HOME_DIR/.config/ama/assets" --output "$HOME_DIR/.config/ama/generated/welcome-overlay.png" || echo "WARNING: welcome overlay build failed; run ama-rebuild after checking assets." >&2
else
  echo "NOTE: Pillow is not installed; welcome overlay generation is optional. Install with: sudo apt install python3-pil" >&2
fi

printf 'Installed AMA Terminal Setup v%s.\n' "$(cat "$ROOT/VERSION" 2>/dev/null || echo unknown)"
printf 'Backup: %s\n' "$BACKUP_DIR"
printf 'Reload with: source ~/.zshrc\n'
