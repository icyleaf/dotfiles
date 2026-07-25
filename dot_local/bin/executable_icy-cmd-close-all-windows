#!/usr/bin/env bash
#
# icy-cmd-close-all-windows: middleware wrapper around omarchy-cmd-close-all-windows
#
# This is the Omarchy-agnostic entry point used by Hyprland/Waybar configs.
# Replace the implementation below to remove the Omarchy dependency.
#
# To replace: implement the desired behaviour directly here and remove
# the delegation to omarchy-cmd-close-all-windows.

if command -v "omarchy-cmd-close-all-windows" >/dev/null 2>&1; then
  exec "omarchy-cmd-close-all-windows" "$@"
else
  echo "icy-cmd-close-all-windows: 'omarchy-cmd-close-all-windows' not found. Install Omarchy or implement a replacement." >&2
  exit 127
fi
