#!/usr/bin/env bash
#
# icy-launch-walker: middleware wrapper around omarchy-launch-walker
#
# This is the Omarchy-agnostic entry point used by Hyprland/Waybar configs.
# Replace the implementation below to remove the Omarchy dependency.
#
# To replace: implement the desired behaviour directly here and remove
# the delegation to omarchy-launch-walker.

if command -v "omarchy-launch-walker" >/dev/null 2>&1; then
  exec "omarchy-launch-walker" "$@"
else
  echo "icy-launch-walker: 'omarchy-launch-walker' not found. Install Omarchy or implement a replacement." >&2
  exit 127
fi
