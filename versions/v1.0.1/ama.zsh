# =========================================================
# AMA Robotics Lab — Zsh configuration
# Portable shell helpers, terminal colors, and prompt hooks.
# =========================================================

[[ -r "$HOME/.config/ama/zsh/paths.zsh" ]] && source "$HOME/.config/ama/zsh/paths.zsh"
export SHELL=/usr/bin/zsh

if (( $+commands[eza] )); then
  export EZA_COLORS='reset:di=38;5;75:fi=38;5;114:ln=38;5;81:or=38;5;203:ex=38;5;114:sc=38;5;208:*.cpp=38;5;208:*.c=38;5;208:*.h=38;5;215:*.hpp=38;5;215:*.py=38;5;221:*.sh=38;5;141:*.bash=38;5;141:*.zsh=38;5;141:*.txt=38;5;252:*.md=38;5;252:*.rst=38;5;252:*.pdf=38;5;203:*.jpg=38;5;213:*.jpeg=38;5;213:*.png=38;5;213:*.gif=38;5;213:*.svg=38;5;213:*.mp3=38;5;45:*.wav=38;5;45:*.mp4=38;5;45:*.mkv=38;5;45:*.zip=38;5;220:*.tar=38;5;220:*.gz=38;5;220:*.7z=38;5;220:*.json=38;5;81:*.xml=38;5;81:*.yaml=38;5;81:*.yml=38;5;81:*.toml=38;5;81:*.ini=38;5;81:*.csv=38;5;81:*.log=38;5;245:*.lock=38;5;245'
  alias ls='eza --icons=auto --group-directories-first --color=always'
  alias ll='eza -lah --icons=auto --group-directories-first --color=always'
  alias la='eza -A --icons=auto --group-directories-first --color=always'
else
  alias ls='ls --color=auto --group-directories-first'
  alias ll='ls -lah --color=auto --group-directories-first'
  alias la='ls -A --color=auto --group-directories-first'
fi

export LS_COLORS='di=01;34:fi=97:ln=36:or=01;31:ex=92:*.cpp=38;5;208:*.c=38;5;208:*.h=38;5;215:*.hpp=38;5;215:*.py=33:*.sh=35:*.bash=35:*.zsh=35:*.json=36:*.yaml=36:*.yml=36:*.toml=36:*.pdf=31:*.png=35:*.jpg=35:*.jpeg=35:*.mp3=36:*.wav=36:*.zip=33:*.tar=33:*.gz=33:*.log=90'
typeset -g AMA_COMPLETION_COLORS='no=97:fi=97:di=1;96:ln=95:or=1;91:ex=1;92:ma=30;103'

if [[ -o interactive ]]; then
  mkdir -p "$HOME/.cache/zsh"
  zmodload zsh/complist 2>/dev/null
  autoload -Uz compinit
  compinit -d "$HOME/.cache/zsh/zcompdump-${ZSH_VERSION}"
  zstyle ':completion:*' list-colors "$AMA_COMPLETION_COLORS"
  zstyle ':completion:*:default' list-colors "$AMA_COMPLETION_COLORS"
  zstyle ':completion:*' menu select
  zstyle ':completion:*:descriptions' format '%F{cyan}-- %d --%f'
  zstyle ':completion:*:messages' format '%F{yellow}%d%f'
  zstyle ':completion:*:warnings' format '%F{red}No matches for: %d%f'
  zstyle ':completion:*:corrections' format '%F{yellow}%d (errors: %e)%f'
fi

alias reloadzsh='source ~/.zshrc'
alias reloadama='source ~/.config/ama/zsh/ama.zsh'
alias lab='cd "$HOME/.config/ama"'
alias ama-assets='xdg-open "$HOME/.config/ama/assets" >/dev/null 2>&1 &!'

clear() { printf '\033[H\033[3J\033[2J'; }

robot() {
  [[ -d "${AMA_ROBOT_WS:-$HOME/robotics_ws}" ]] || { print -u2 "AMA: workspace not found: ${AMA_ROBOT_WS:-$HOME/robotics_ws}"; return 1; }
  cd "${AMA_ROBOT_WS:-$HOME/robotics_ws}"
}

cpp() {
  [[ -d "${AMA_CPP_DIR:-$HOME/cpp_study}" ]] || { print -u2 "AMA: C++ folder not found: ${AMA_CPP_DIR:-$HOME/cpp_study}"; return 1; }
  cd "${AMA_CPP_DIR:-$HOME/cpp_study}"
}

lps() {
  [[ -d "${AMA_LPS_DIR:-$HOME/LPS}" ]] || { print -u2 "AMA: LPS folder not found at ${AMA_LPS_DIR:-$HOME/LPS}; edit ~/.config/ama/zsh/paths.zsh."; return 1; }
  cd "${AMA_LPS_DIR:-$HOME/LPS}"
}

rosenv() {
  local setup=""
  if [[ -n "${ROS_DISTRO:-}" && -f "/opt/ros/$ROS_DISTRO/setup.zsh" ]]; then
    setup="/opt/ros/$ROS_DISTRO/setup.zsh"
  elif [[ -f /opt/ros/humble/setup.zsh ]]; then
    setup=/opt/ros/humble/setup.zsh
  else
    local -a setups
    setups=(/opt/ros/*/setup.zsh(N))
    if (( ${#setups[@]} == 1 )); then setup="${setups[1]}"; fi
  fi
  [[ -n "$setup" && -f "$setup" ]] || { print -u2 "AMA: no ROS setup.zsh found under /opt/ros."; return 1; }
  source "$setup"
  print "AMA: sourced $setup"
}

ama() {
  local choice
  print ""
  print "  AMA ROBOTICS LAB — Quick Access"
  print "  1) Robotics workspace  (${AMA_ROBOT_WS:-$HOME/robotics_ws})"
  print "  2) C++ study           (${AMA_CPP_DIR:-$HOME/cpp_study})"
  print "  3) AMA assets          ($HOME/.config/ama/assets)"
  print "  4) AMA settings        ($HOME/.config/ama)"
  print "  5) Home                ($HOME)"
  print "  6) Exit"
  print ""
  read "choice?Choose [1-6]: "
  case "$choice" in
    1) robot ;;
    2) cpp ;;
    3) cd "$HOME/.config/ama/assets" ;;
    4) cd "$HOME/.config/ama" ;;
    5) cd "$HOME" ;;
    6) return 0 ;;
    *) print -u2 "Choose a number from 1 to 6."; return 2 ;;
  esac
}

ama-welcome() { "$HOME/.config/ama/scripts/welcome.sh"; }

ama-rebuild() {
  local py="$HOME/.config/ama/scripts/build_welcome.py"
  local assets="$HOME/.config/ama/assets"
  local out="$HOME/.config/ama/generated/welcome-overlay.png"
  if ! python3 -c 'from PIL import Image' >/dev/null 2>&1; then
    print -u2 "Pillow is missing. Install it with: sudo apt install python3-pil"
    return 1
  fi
  python3 "$py" --assets "$assets" --output "$out" || return $?
  if [[ -s "$assets/09_kitty_icon.png" ]] && command file "$assets/09_kitty_icon.png" | grep -qv '1 x 1'; then
    cp "$assets/09_kitty_icon.png" "$HOME/.config/kitty/kitty.app.png"
    print "Kitty icon copied. Restart Kitty to see it."
  fi
  print "Overlay rebuilt. Run ama-welcome to preview it; Ctrl+Shift+F5 reloads Kitty settings."
}

_ama_set_window_title() {
  [[ -n "${KITTY_WINDOW_ID:-}" ]] || return 0
  local current_dir="${PWD/#$HOME/~}"
  local title_prefix='  𝒜ℳ𝒜  ⌬    AMA  /  ROBOTICS LAB       ◆       ENGINEERING HUB    ┃    '
  local path_separator='        ▸⌬▸        '
  local fish='𓆝 𓆟 𓆞 𓆝 𓆟'
  local full_dir display_dir short_dir title
  full_dir=$(printf '%s' "$current_dir" | sed "s|/|${path_separator}|g")
  display_dir="$full_dir"
  title="${title_prefix}${display_dir}"
  if (( ${#title} > 120 )); then
    short_dir="…${path_separator}${fish}${path_separator}${PWD:t}"
    display_dir="$short_dir"
    title="${title_prefix}${display_dir}"
  fi
  printf '\033]0;%s\a' "$title"
}

typeset -g _AMA_COMMAND_RAN=0
typeset -g AMA_LAST_RESULT="${AMA_LAST_RESULT:-none}"
typeset -g AMA_PROMPT_MODE="${AMA_PROMPT_MODE:-idle}"

_ama_status_preexec() {
  _AMA_COMMAND_RAN=1
  AMA_LAST_RESULT=running
  AMA_PROMPT_MODE=idle
  export AMA_LAST_RESULT AMA_PROMPT_MODE
}

_ama_status_precmd() {
  local rc=$?
  (( _AMA_COMMAND_RAN == 0 )) && return $rc
  if (( rc == 0 )); then
    printf '\n\033[1;92m• ✔ 𓆝𓆟༝˚｡⋆𓆉︎⋆｡˚༝𓆞𓆝  ˙ᵕ˙\033[0m\n'
    AMA_LAST_RESULT=success
  else
    printf '\n\033[1;91m• ✗ ☠ ﹏𓊝﹏𓂁﹏   °◠°      خطأ☠     \033[0m\n'
    AMA_LAST_RESULT=failure
  fi
  AMA_PROMPT_MODE=idle
  _AMA_COMMAND_RAN=0
  export AMA_LAST_RESULT AMA_PROMPT_MODE
  return $rc
}

preexec_functions=(${preexec_functions:#_ama_status_preexec})
preexec_functions=(_ama_status_preexec ${preexec_functions})
precmd_functions=(${precmd_functions:#_ama_status_precmd})
precmd_functions=(${precmd_functions:#_ama_set_window_title})
precmd_functions=(_ama_status_precmd _ama_set_window_title ${precmd_functions})
alias bat="batcat"
alias fd='fdfind'
