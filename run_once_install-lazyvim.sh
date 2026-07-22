#!/usr/bin/env bash
#
# Install LazyVim Starter for Neovim

set -euo pipefail

NVIM_PATH="${HOME}/.config/nvim"

if [ ! -d "${NVIM_PATH}" ]; then
  if command -v nvim &>/dev/null; then
    echo "Installing LazyVim starter..."
    git clone https://github.com/LazyVim/starter "${NVIM_PATH}"
    echo "LazyVim starter installed successfully."
  else
    echo "Neovim (nvim) is not installed, skipping LazyVim starter installation."
  fi
else
  echo "Neovim configuration already exists, skipping."
fi
