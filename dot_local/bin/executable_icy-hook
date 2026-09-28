#!/usr/bin/env bash
#
# icy-hook: middleware wrapper around omarchy-hook
#
# This is the Omarchy-agnostic entry point used by Hyprland/Waybar configs.
# Replace the implementation below to remove the Omarchy dependency.
#
# To replace: implement the desired behaviour directly here and remove
# the delegation to omarchy-hook.

if command -v "omarchy-hook" >/dev/null 2>&1; then
  exec "omarchy-hook" "$@"
else
  echo "icy-hook: 'omarchy-hook' not found. Install Omarchy or implement a replacement." >&2
  exit 127
fi
