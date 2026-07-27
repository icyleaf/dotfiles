#!/usr/bin/env bash
set -euo pipefail

if ! command -v wev >/dev/null 2>&1; then
  cat >&2 <<'MSG'
wev is not installed. Install it, or run evtest and look for BTN_SIDE/BTN_EXTRA.
MSG
  exit 1
fi

cat >&2 <<'MSG'
A small wev window will open.
Move the pointer into that window, press the mouse button you want to bind,
then watch this terminal for the Hyprland token.
MSG

wev -f wl_pointer:button | while IFS= read -r line; do
  case "$line" in
    *"button:"*)
      button="$(printf '%s\n' "$line" | sed -n 's/.*button: \([0-9][0-9]*\).*/\1/p')"
      name="$(printf '%s\n' "$line" | sed -n 's/.*button: [0-9][0-9]* (\([^)]*\)).*/\1/p')"
      state="$(printf '%s\n' "$line" | sed -n 's/.*state: [0-9][0-9]* (\([^)]*\)).*/\1/p')"
      if [[ -n "$button" && ( -z "$state" || "$state" == "pressed" ) ]]; then
        printf '\nDetected: button %s' "$button"
        [[ -n "$name" ]] && printf ' (%s)' "$name"
        printf '\nHyprland token: mouse:%s\n\n' "$button"
        printf 'Use it in ~/.config/hypr/bindings.lua, for example:\n'
        printf '  o.bind("mouse:%s", "Orbit press", "~/.config/omarchy/plugins/orbit/scripts/orbit-press.sh --button %s", { locked = true })\n' "$button" "$button"
        printf '  o.bind("mouse:%s", "Orbit release fallback", "~/.config/omarchy/plugins/orbit/scripts/orbit-release.sh", { locked = true, release = true })\n' "$button"
        exit 0
      fi
      ;;
  esac
done
