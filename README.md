# AMA-Terminal-Setup

A portable Linux terminal environment for AMA Robotics. The repository contains Zsh helpers, Starship prompt configuration, Kitty theme, tmux/btop/lazygit configuration, welcome-screen scripts, brand artwork, and optional launch audio.

## Install

```bash
chmod +x install.sh
./install.sh
source ~/.zshrc
./doctor.sh
```

The installer creates timestamped backups before replacing destination files. It does not install every optional terminal utility; use `doctor.sh` to see which tools are already available. ROS 2 integration appears only when a ROS setup file is installed and sourced on that machine.

## Welcome and launch assets

- `assets/ama-robotics/`: public/default brand artwork and Kitty background.
- `assets/audio/`: small optional sound files used by launchers.
- `scripts/welcome/`: welcome overlay builder and preview script.
- `scripts/launchers/`: portable Kitty and VS Code wrappers.
- `configs/zsh/zshrc.ama-template`: reference template captured from the current AMA setup; the installer appends only the required integration lines instead of replacing a user's entire `.zshrc`.
- `configs/fastfetch/config.jsonc`: current Fastfetch layout, when present on the source machine.
- Personal profile/signature artwork may be kept locally in `~/.config/ama/assets/` and is not required for the public default.
- Large Python virtual environments, ONNX models, and logs are deliberately excluded. Optional sound playback requires a suitable local player such as `mpg123`, `ffplay`, `paplay`, or `aplay`.

## Recovery

The installer stores backups under `~/.config/ama/backups/`. Review them before restoring prior settings. Run `doctor.sh` after installing and test on a disposable account or virtual machine before sharing the installer broadly.

## Releases

See `versions/` and GitHub Releases for version-specific notes.
