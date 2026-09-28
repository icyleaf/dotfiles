#!/usr/bin/env bash
#
# icy-transcode: middleware wrapper around omarchy-transcode
#
# This is the Omarchy-agnostic entry point used by Hyprland/Waybar configs.
# Replace the implementation below to remove the Omarchy dependency.
#
# To replace: implement the desired behaviour directly here and remove
# the delegation to omarchy-transcode.

if command -v "omarchy-transcode" >/dev/null 2>&1; then
  exec "omarchy-transcode" "$@"
else
  echo "icy-transcode: 'omarchy-transcode' not found. Install Omarchy or implement a replacement." >&2
  exit 127
fi
