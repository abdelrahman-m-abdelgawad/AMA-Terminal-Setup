# AMA portable launchers. Sourced at the end of ~/.zshrc to override older local wrappers.
kitty() {
  local launcher="$HOME/.config/ama/scripts/launch_kitty.sh"
  if [[ ! -x "$launcher" ]]; then command kitty "$@"; return $?; fi
  if [[ $# -eq 0 && -z "${KITTY_WINDOW_ID:-}" && "${TERM:-}" != "xterm-kitty" ]]; then
    local kitty_dir="$PWD"
    fc -AI 2>/dev/null || true
    nohup "$launcher" --directory "$kitty_dir" >/dev/null 2>&1 &!
    sleep 0.5
    exit
  else
    "$launcher" "$@"
  fi
}

code() {
  local launcher="$HOME/.config/ama/scripts/launch_vscode.sh"
  if [[ -x "$launcher" ]]; then "$launcher" --force-user-env "$@"
  elif command -v code >/dev/null 2>&1; then command code --force-user-env "$@"
  else print -u2 "AMA: VS Code executable was not found."; return 127
  fi
}
