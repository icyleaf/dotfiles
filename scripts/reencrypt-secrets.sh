#!/usr/bin/env bash
# reencrypt-secrets.sh
#
# Re-encrypt every shared secret under secrets/base/ to all age recipients
# listed in secrets/recipients.txt.
#
# Run this after adding a new machine's public key to secrets/recipients.txt,
# so the new machine can decrypt the shared secrets.
#
# Profile-only secrets under secrets/profiles/<profile>/ are intentionally left
# untouched: they are encrypted to their owning machine's key alone.
#
# Usage:
#   scripts/reencrypt-secrets.sh [identity-file]
#
# The identity file defaults to $AGE_IDENTITY, then
# ~/.local/share/age/default-key.txt. It only needs to be a key that can
# already decrypt the shared secrets.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RECIPIENTS="${REPO_DIR}/secrets/recipients.txt"
BASE_DIR="${REPO_DIR}/secrets/base"
IDENTITY="${1:-${AGE_IDENTITY:-${HOME}/.local/share/age/default-key.txt}}"

if ! command -v age >/dev/null 2>&1; then
  echo "Error: age CLI not found." >&2
  exit 1
fi

if [ ! -f "${RECIPIENTS}" ]; then
  echo "Error: recipients file not found: ${RECIPIENTS}" >&2
  exit 1
fi

if [ ! -f "${IDENTITY}" ]; then
  echo "Error: age identity not found: ${IDENTITY}" >&2
  exit 1
fi

if [ ! -d "${BASE_DIR}" ]; then
  echo "Error: base secrets directory not found: ${BASE_DIR}" >&2
  exit 1
fi

count=0
while IFS= read -r file; do
  tmp="$(mktemp)"
  trap 'rm -f "${tmp}"' EXIT

  if ! age --decrypt -i "${IDENTITY}" "${file}" >"${tmp}" 2>/dev/null; then
    echo "Error: cannot decrypt ${file#"${REPO_DIR}/"} with ${IDENTITY}" >&2
    rm -f "${tmp}"
    exit 1
  fi

  age --encrypt -R "${RECIPIENTS}" -o "${file}" "${tmp}"
  rm -f "${tmp}"
  trap - EXIT
  echo "Re-encrypted ${file#"${REPO_DIR}/"}"
  count=$((count + 1))
done < <(find "${BASE_DIR}" -type f -name '*.age' | sort)

echo "Done. Re-encrypted ${count} shared secret(s) to $(grep -c '^age1' "${RECIPIENTS}") recipient(s)."
