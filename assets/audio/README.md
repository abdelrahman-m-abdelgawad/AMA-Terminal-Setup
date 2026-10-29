# AMA audio assets

The installer includes the small Kitty startup voice files and the VS Code coding sound when present on the source machine. The other small sound samples are kept in `optional/` for future integrations.

Large Piper/ONNX voice models and Python virtual environments are deliberately not bundled: virtual environments are machine/Python-version specific, and model files can be large. They should be installed separately only if a future optional voice feature needs them.

Audio playback is optional. The terminal launchers still open Kitty/VS Code when no supported audio player is installed.
