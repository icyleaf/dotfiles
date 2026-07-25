#!/usr/bin/env bash
#
# icy-system-wake: middleware wrapper around omarchy-system-wake
#
# This is the Omarchy-agnostic entry point used by Hyprland/Waybar configs.
# Replace the implementation below to remove the Omarchy dependency.
#
# To replace: implement the desired behaviour directly here and remove
# the delegation to omarchy-system-wake.

if command -v "omarchy-system-wake" >/dev/null 2>&1; then
  exec "omarchy-system-wake" "$@"
else
  echo "icy-system-wake: 'omarchy-system-wake' not found. Install Omarchy or implement a replacement." >&2
  exit 127
fi
