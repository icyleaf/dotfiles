#!/usr/bin/env bash
#
# Chezmoi installation state validation script

set -euo pipefail

# Locate the repository root dynamically (supporting execution from any directory)
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_DIR=$(cd "${SCRIPT_DIR}/.." && pwd)
CHEZMOI_BIN="${REPO_DIR}/bin/chezmoi"

if [ ! -f "${CHEZMOI_BIN}" ]; then
  echo "FAIL: chezmoi binary not found at ${CHEZMOI_BIN}"
  exit 1
fi

# Setup a clean test HOME directory to verify default resolution (non-tautological)
TEST_HOME="/tmp/dotfiles-test-home"
rm -rf "${TEST_HOME}"
mkdir -p "${TEST_HOME}/.local/share"

# Symlink the repository to ~/.local/share/chezmoi as a real deployment would
ln -sf "${REPO_DIR}" "${TEST_HOME}/.local/share/chezmoi"

# Verify that running chezmoi source-path naturally matches the repository root
actual_source=$(HOME="${TEST_HOME}" "${CHEZMOI_BIN}" source-path)
resolved_source=$(realpath "${actual_source}")
resolved_repo=$(realpath "${REPO_DIR}")

if [ "${resolved_source}" != "${resolved_repo}" ]; then
  echo "FAIL: chezmoi source-path (${resolved_source}) does not match expected (${resolved_repo})"
  exit 1
fi

echo "PASS: chezmoi source-path matches repository root (${REPO_DIR})"
exit 0
