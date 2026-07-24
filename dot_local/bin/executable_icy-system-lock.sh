#!/usr/bin/env bash
#
# icy-system-lock: middleware wrapper around omarchy-system-lock
#
# This is the Omarchy-agnostic entry point used by Hyprland/Waybar configs.
# Replace the implementation below to remove the Omarchy dependency.
#
# To replace: implement the desired behaviour directly here and remove
# the delegation to omarchy-system-lock.

if command -v "omarchy-system-lock" >/dev/null 2>&1; then
  exec "omarchy-system-lock" "$@"
else
  echo "icy-system-lock: 'omarchy-system-lock' not found. Install Omarchy or implement a replacement." >&2
  exit 127
fi
