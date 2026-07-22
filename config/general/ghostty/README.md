# Ghostty Configuration

This module manages the cross-platform [Ghostty](https://mitchellh.com/ghostty) terminal configuration.

## Submodule Integration
It uses the upstream [Arakiss/ghostty-warp](https://github.com/Arakiss/ghostty-warp) repository as a Git Submodule under the `warp/` folder to manage presets, themes, fonts, and the `gconfig` switcher tool.

## Custom Overrides
Any local files placed in this directory (e.g. `config`, `presets/`, `themes/`, `fonts/`) will automatically overlay and override the corresponding upstream files in `~/.config/ghostty/` when deployed.
