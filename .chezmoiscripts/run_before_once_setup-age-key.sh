#!/usr/bin/env bash
# run_before_once_setup-age-key.sh
#
# Generates a shared age key pair at ~/.local/share/age/default-key.txt
# if it does not already exist.
# Missing age-keygen is non-fatal so `chezmoi init --apply` can continue;
# secret deployment is skipped later when the identity or CLI is unavailable.

set -euo pipefail

KEY_DIR="${HOME}/.local/share/age"
KEY_FILE="${KEY_DIR}/default-key.txt"

if [ -f "${KEY_FILE}" ]; then
  exit 0
fi

if ! command -v age-keygen >/dev/null 2>&1; then
  echo "Warning: age-keygen not found; skipping age key setup." >&2
  echo "Install age (e.g. sudo pacman -S age) and re-run to generate ${KEY_FILE}." >&2
  exit 0
fi

echo "Setting up age private key..."
mkdir -p "${KEY_DIR}"
chmod 700 "${KEY_DIR}"
age-keygen -o "${KEY_FILE}"
chmod 600 "${KEY_FILE}"
echo "New age private key generated at ${KEY_FILE}"
echo "Public key:"
age-keygen -y "${KEY_FILE}"
