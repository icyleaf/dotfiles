#!/usr/bin/env bash
#
# icy-launch-floating-terminal: middleware wrapper around omarchy-launch-floating-terminal-with-presentation
#
# This is the Omarchy-agnostic entry point used by Hyprland/Waybar configs.
# Replace the implementation below to remove the Omarchy dependency.
#
# To replace: implement the desired behaviour directly here and remove
# the delegation to omarchy-launch-floating-terminal-with-presentation.

if command -v "omarchy-launch-floating-terminal-with-presentation" >/dev/null 2>&1; then
  exec "omarchy-launch-floating-terminal-with-presentation" "$@"
else
  echo "icy-launch-floating-terminal: 'omarchy-launch-floating-terminal-with-presentation' not found. Install Omarchy or implement a replacement." >&2
  exit 127
fi
