#!/usr/bin/env bash
#
# icy-cmd-screenshot: middleware wrapper around omarchy-cmd-screenshot
#
# This is the Omarchy-agnostic entry point used by Hyprland/Waybar configs.
# Replace the implementation below to remove the Omarchy dependency.
#
# To replace: implement the desired behaviour directly here and remove
# the delegation to omarchy-cmd-screenshot.

if command -v "omarchy-cmd-screenshot" >/dev/null 2>&1; then
  exec "omarchy-cmd-screenshot" "$@"
else
  echo "icy-cmd-screenshot: 'omarchy-cmd-screenshot' not found. Install Omarchy or implement a replacement." >&2
  exit 127
fi
