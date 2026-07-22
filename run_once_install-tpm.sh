#!/usr/bin/env bash
#
# Install TPM (Tmux Plugin Manager)

set -euo pipefail

TPM_PATH="${HOME}/.tmux/plugins/tpm"

if [ ! -d "${TPM_PATH}" ]; then
  echo "Installing tmux plugin manager (tpm)..."
  mkdir -p "$(dirname "${TPM_PATH}")"
  git clone https://github.com/tmux-plugins/tpm "${TPM_PATH}"
  echo "TPM installed successfully."
else
  echo "TPM is already installed, skipping."
fi
