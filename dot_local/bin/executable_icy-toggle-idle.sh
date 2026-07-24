#!/usr/bin/env bash
#
# icy-toggle-idle: middleware wrapper around omarchy-toggle-idle
#
# This is the Omarchy-agnostic entry point used by Hyprland/Waybar configs.
# Replace the implementation below to remove the Omarchy dependency.
#
# To replace: implement the desired behaviour directly here and remove
# the delegation to omarchy-toggle-idle.

if command -v "omarchy-toggle-idle" >/dev/null 2>&1; then
  exec "omarchy-toggle-idle" "$@"
else
  echo "icy-toggle-idle: 'omarchy-toggle-idle' not found. Install Omarchy or implement a replacement." >&2
  exit 127
fi
