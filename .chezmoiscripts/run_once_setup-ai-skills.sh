#!/usr/bin/env bash
#
# Install global AI agent skills from upstream skill packages via the
# `skills` CLI (https://skills.sh).
#
# Installs to ~/.agents/skills/, the shared global location read by
# OpenCode and other agents. Non-interactive (`-g -y`) so it is safe to run
# during `chezmoi apply`.
#
# To refresh later:  npx skills@latest update -g -y

set -euo pipefail

SKILL_PACKAGES=(
  "mattpocock/skills"
)

# npx comes from the mise-managed node toolchain. Skip (non-fatal) when it is
# not yet available so a first apply on a fresh machine is never blocked.
if ! command -v npx >/dev/null 2>&1; then
  echo "Warning: npx not found; skipping AI skills install." >&2
  echo "Install Node (mise install node) and re-run 'chezmoi apply'." >&2
  exit 0
fi

install_package() {
  local package="$1"
  echo "Installing skills from ${package}..."
  if npx --yes "skills@latest" add "${package}" --global --yes; then
    echo "Installed skills from ${package}."
  else
    echo "Warning: failed to install skills from ${package}." >&2
  fi
}

for package in "${SKILL_PACKAGES[@]}"; do
  install_package "${package}"
done
