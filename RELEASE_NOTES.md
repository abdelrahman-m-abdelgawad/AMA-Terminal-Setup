# Release notes

## v1.0.1 — portable welcome and launch assets
- Bundle welcome builder and preview script into the installer deployment paths.
- Bundle default AMA artwork and small launch audio assets.
- Replace hard-coded `~/Music/AMA_Welcome` dependencies with installed configuration paths.
- Preserve local files with timestamped backups and add portability checks to `doctor.sh`.
- Synchronize the active Starship/Kitty/Zsh/Tmux/Btop/Fastfetch configs into the repo to avoid regressing the tested setup.
- Exclude Python virtual environments, large ONNX models, logs, and personal profile assets from the public release.
