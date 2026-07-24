#!/usr/bin/env bash
#
# icy-menu: middleware wrapper around omarchy-menu
#
# This is the Omarchy-agnostic entry point used by Hyprland/Waybar configs.
# Replace the implementation below to remove the Omarchy dependency.
#
# To replace: implement the desired behaviour directly here and remove
# the delegation to omarchy-menu.

if command -v "omarchy-menu" >/dev/null 2>&1; then
  exec "omarchy-menu" "$@"
else
  echo "icy-menu: 'omarchy-menu' not found. Install Omarchy or implement a replacement." >&2
  exit 127
fi
