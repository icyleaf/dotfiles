#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ring="${OMARCHY_ORBIT_RING:-}"
mode="${OMARCHY_ORBIT_MODE:-hold}"
button="${OMARCHY_ORBIT_BUTTON:-}"
watch_release="${OMARCHY_ORBIT_WATCH_RELEASE:-auto}"
x=-1
y=-1

while (( $# > 0 )); do
  case "$1" in
    --button)
      button="${2:-}"
      shift 2
      ;;
    --mode)
      mode="${2:-hold}"
      shift 2
      ;;
    --ring)
      ring="${2:-}"
      shift 2
      ;;
    --no-watch-release)
      watch_release="0"
      shift
      ;;
    --)
      shift
      break
      ;;
    *)
      # Back-compat: the first positional argument is the ring id.
      if [[ -z "$ring" ]]; then ring="$1"; fi
      shift
      ;;
  esac
done

if [[ "$watch_release" != "0" && -n "$button" && "$button" =~ ^[0-9]+$ ]]; then
  "$script_dir/watch-release.py" "$button" >/dev/null 2>&1 &
fi

if pos="$(hyprctl cursorpos 2>/dev/null)" && [[ "$pos" =~ ^(-?[0-9]+),[[:space:]]*(-?[0-9]+)$ ]]; then
  x="${BASH_REMATCH[1]}"
  y="${BASH_REMATCH[2]}"
fi

# Hyprland reports cursor positions in global monitor-layout coordinates.
# Quickshell's overlay receives local coordinates for the screen it appears on,
# so subtract the containing monitor's origin when jq is available.
if command -v jq >/dev/null 2>&1 && [[ "$x" != "-1" ]]; then
  monitor="$(hyprctl -j monitors 2>/dev/null | jq -r --argjson cx "$x" --argjson cy "$y" '
    map(select($cx >= .x and $cx < (.x + .width) and $cy >= .y and $cy < (.y + .height)))
    | .[0] // empty
    | [.x, .y]
    | @tsv
  ' 2>/dev/null || true)"
  if [[ -n "$monitor" ]]; then
    read -r mx my <<<"$monitor"
    if [[ "$mx" =~ ^-?[0-9]+$ && "$my" =~ ^-?[0-9]+$ ]]; then
      x=$((x - mx))
      y=$((y - my))
    fi
  fi
fi

if command -v jq >/dev/null 2>&1; then
  payload="$(jq -nc --arg mode "$mode" --arg ring "$ring" --argjson x "$x" --argjson y "$y" \
    '{mode:$mode,x:$x,y:$y} + (if $ring == "" then {} else {ring:$ring} end)')"
else
  escaped_mode="${mode//\\/\\\\}"; escaped_mode="${escaped_mode//\"/\\\"}"
  escaped_ring="${ring//\\/\\\\}"; escaped_ring="${escaped_ring//\"/\\\"}"
  payload="{\"mode\":\"$escaped_mode\",\"x\":$x,\"y\":$y"
  if [[ -n "$ring" ]]; then payload+=",\"ring\":\"$escaped_ring\""; fi
  payload+="}"
fi

omarchy-shell shell summon local.orbit "$payload"
