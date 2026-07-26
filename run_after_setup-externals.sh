#!/bin/bash

CURRENT_DIR="$HOME/.dotfiles"

# soft link omarchy to vendor/omarchy
OMARCHY_SRC="$HOME/.local/share/omarchy"
OMARCHY_DEST="$CURRENT_DIR/vendor/omarchy"

if [[ ! -L "$OMARCHY_DEST" && -d "$OMARCHY_SRC" ]]; then
  ln -s "$OMARCHY_SRC" "$OMARCHY_DEST"
fi