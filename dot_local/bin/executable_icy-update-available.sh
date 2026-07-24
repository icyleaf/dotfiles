#!/usr/bin/env bash
#
# icy-update-available: middleware wrapper around omarchy-update-available
#
# This is the Omarchy-agnostic entry point used by Hyprland/Waybar configs.
# Replace the implementation below to remove the Omarchy dependency.
#
# To replace: implement the desired behaviour directly here and remove
# the delegation to omarchy-update-available.

if command -v "omarchy-update-available" >/dev/null 2>&1; then
  exec "omarchy-update-available" "$@"
else
  echo "icy-update-available: 'omarchy-update-available' not found. Install Omarchy or implement a replacement." >&2
  exit 127
fi
