#!/usr/bin/env bash
#
# icy-weather-status: middleware wrapper around omarchy-weather-status
#
# This is the Omarchy-agnostic entry point used by Hyprland/Waybar configs.
# Replace the implementation below to remove the Omarchy dependency.
#
# To replace: implement the desired behaviour directly here and remove
# the delegation to omarchy-weather-status.

if command -v "omarchy-weather-status" >/dev/null 2>&1; then
  exec "omarchy-weather-status" "$@"
else
  echo "icy-weather-status: 'omarchy-weather-status' not found. Install Omarchy or implement a replacement." >&2
  exit 127
fi
