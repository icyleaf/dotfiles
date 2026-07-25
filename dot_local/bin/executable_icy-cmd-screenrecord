#!/usr/bin/env bash
#
# icy-cmd-screenrecord: middleware wrapper around omarchy-cmd-screenrecord
#
# This is the Omarchy-agnostic entry point used by Hyprland/Waybar configs.
# Replace the implementation below to remove the Omarchy dependency.
#
# To replace: implement the desired behaviour directly here and remove
# the delegation to omarchy-cmd-screenrecord.

if command -v "omarchy-cmd-screenrecord" >/dev/null 2>&1; then
  exec "omarchy-cmd-screenrecord" "$@"
else
  echo "icy-cmd-screenrecord: 'omarchy-cmd-screenrecord' not found. Install Omarchy or implement a replacement." >&2
  exit 127
fi
