#!/usr/bin/env bash
#
# Chezmoi installation state validation script

set -euo pipefail

# 1. Verify that running chezmoi source-path matches the repository root
actual_source=$(./bin/chezmoi --source "$PWD" source-path)
if [ "$actual_source" != "$PWD" ]; then
  echo "FAIL: chezmoi source-path ($actual_source) does not match expected ($PWD)"
  exit 1
fi

echo "PASS: chezmoi source-path matches repository root ($PWD)"
exit 0
