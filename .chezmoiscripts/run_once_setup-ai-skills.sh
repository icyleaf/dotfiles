#!/usr/bin/env bash
#
# Install global AI agent skills from upstream skill packages via the
# `skills` CLI (https://skills.sh).
#
# Installs to ~/.agents/skills/, the shared global location read by
# OpenCode and Antigravity CLI. Non-interactive (`-g -y`) so it is safe to
# run during `chezmoi apply`.
#
# Agents are listed explicitly: without `-a`, the CLI auto-detects every
# installable agent (including PromptScript and Eve) and reports a spurious
# "Failed to install" for each global-incompatible agent.
#
# To refresh later:  npx skills@latest update -g -y

set -euo pipefail

SKILL_PACKAGES=(
  "mattpocock/skills"
)

SKILL_AGENTS=(
  "opencode"
  "antigravity-cli"
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
  shift
  local agent_args=()
  for agent in "$@"; do
    agent_args+=(-a "${agent}")
  done

  echo "Installing skills from ${package}..."
  if npx --yes "skills@latest" add "${package}" --global --yes "${agent_args[@]}"; then
    echo "Installed skills from ${package}."
  else
    echo "Warning: failed to install skills from ${package}." >&2
  fi
}

for package in "${SKILL_PACKAGES[@]}"; do
  install_package "${package}" "${SKILL_AGENTS[@]}"
done
