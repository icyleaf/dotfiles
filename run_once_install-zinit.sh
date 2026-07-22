#!/usr/bin/env bash
#
# Install Zinit (Zsh Plugin Manager)

set -euo pipefail

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

if [ ! -d "${ZINIT_HOME}" ]; then
  echo "Installing zinit..."
  mkdir -p "$(dirname "${ZINIT_HOME}")"
  git clone https://github.com/zdharma-continuum/zinit.git "${ZINIT_HOME}"
  echo "Zinit installed successfully."
else
  echo "Zinit is already installed, skipping."
fi
