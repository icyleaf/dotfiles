#!/usr/bin/env bash
#
# icy-launch-tui: middleware wrapper around omarchy-launch-tui
#
# This is the Omarchy-agnostic entry point used by Hyprland/Waybar configs.
# Replace the implementation below to remove the Omarchy dependency.
#
# To replace: implement the desired behaviour directly here and remove
# the delegation to omarchy-launch-tui.

if command -v "omarchy-launch-tui" >/dev/null 2>&1; then
  exec "omarchy-launch-tui" "$@"
else
  echo "icy-launch-tui: 'omarchy-launch-tui' not found. Install Omarchy or implement a replacement." >&2
  exit 127
fi
