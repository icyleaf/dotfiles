#!/usr/bin/env bash
#
# icy-capture-text: middleware wrapper around omarchy-capture-text-extraction
#
# This is the Omarchy-agnostic entry point used by Hyprland/Waybar configs.
# Replace the implementation below to remove the Omarchy dependency.
#
# To replace: implement the desired behaviour directly here and remove
# the delegation to omarchy-capture-text-extraction.

if command -v "omarchy-capture-text-extraction" >/dev/null 2>&1; then
  exec "omarchy-capture-text-extraction" "$@"
else
  echo "icy-capture-text: 'omarchy-capture-text-extraction' not found. Install Omarchy or implement a replacement." >&2
  exit 127
fi
