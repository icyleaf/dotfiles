#!/bin/bash

CURRENT_DIR="$HOME/.dotfiles"

# Prefer a system-wide Omarchy install; fall back to the user clone created by
# Chezmoi externals (.chezmoiexternals/03_omarchy.toml.tmpl).
if [[ -d /usr/share/omarchy ]]; then
  OMARCHY_SRC="/usr/share/omarchy"
else
  OMARCHY_SRC="$HOME/.local/share/omarchy"
fi
OMARCHY_DEST="$CURRENT_DIR/vendor/omarchy"

if [[ -d "$OMARCHY_SRC" ]]; then
  ln -sfn "$OMARCHY_SRC" "$OMARCHY_DEST"
fi
