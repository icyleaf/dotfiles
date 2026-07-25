#!/usr/bin/env bash
#
# icy-launch-browser: middleware wrapper around omarchy-launch-browser
#
# This is the Omarchy-agnostic entry point used by Hyprland/Waybar configs.
# Replace the implementation below to remove the Omarchy dependency.
#
# To replace: implement the desired behaviour directly here and remove
# the delegation to omarchy-launch-browser.

if command -v "omarchy-launch-browser" >/dev/null 2>&1; then
  exec "omarchy-launch-browser" "$@"
else
  echo "icy-launch-browser: 'omarchy-launch-browser' not found. Install Omarchy or implement a replacement." >&2
  exit 127
fi
