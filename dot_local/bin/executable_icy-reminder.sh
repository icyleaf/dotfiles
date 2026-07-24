#!/usr/bin/env bash
#
# icy-reminder: middleware wrapper around omarchy-reminder
#
# This is the Omarchy-agnostic entry point used by Hyprland/Waybar configs.
# Replace the implementation below to remove the Omarchy dependency.
#
# To replace: implement the desired behaviour directly here and remove
# the delegation to omarchy-reminder.

if command -v "omarchy-reminder" >/dev/null 2>&1; then
  exec "omarchy-reminder" "$@"
else
  echo "icy-reminder: 'omarchy-reminder' not found. Install Omarchy or implement a replacement." >&2
  exit 127
fi
