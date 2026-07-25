#!/usr/bin/env bash
#
# icy-battery-status: middleware wrapper around omarchy-battery-status
#
# This is the Omarchy-agnostic entry point used by Hyprland/Waybar configs.
# Replace the implementation below to remove the Omarchy dependency.
#
# To replace: implement the desired behaviour directly here and remove
# the delegation to omarchy-battery-status.

if command -v "omarchy-battery-status" >/dev/null 2>&1; then
  exec "omarchy-battery-status" "$@"
else
  echo "icy-battery-status: 'omarchy-battery-status' not found. Install Omarchy or implement a replacement." >&2
  exit 127
fi
