#!/usr/bin/env bash
#
# icy-cmd-terminal-cwd: middleware wrapper around omarchy-cmd-terminal-cwd
#
# This is the Omarchy-agnostic entry point used by Hyprland/Waybar configs.
# Replace the implementation below to remove the Omarchy dependency.
#
# To replace: implement the desired behaviour directly here and remove
# the delegation to omarchy-cmd-terminal-cwd.

if command -v "omarchy-cmd-terminal-cwd" >/dev/null 2>&1; then
  exec "omarchy-cmd-terminal-cwd" "$@"
else
  echo "icy-cmd-terminal-cwd: 'omarchy-cmd-terminal-cwd' not found. Install Omarchy or implement a replacement." >&2
  exit 127
fi
