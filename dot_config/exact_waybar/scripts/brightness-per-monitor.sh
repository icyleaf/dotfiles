#!/bin/bash

# --- CONFIGURATION ---
STEP=5
STATE_FILE_PREFIX="/tmp/waybar_brightness"
# ---------------------
# External monitors use wl-gammarelay-rs (software gamma via D-Bus) since
# DDC-CI is not available through the docking station (MST blocks I2C).
# Laptop display (eDP-1) uses brightnessctl for real hardware backlight control.
# Make sure wl-gammarelay-rs daemon is running (e.g. via hyprland exec-once).

# Get monitor name - either from argument, env var, or focused monitor
get_monitor_name() {
  if [[ -n "$1" ]]; then
    echo "$1"
  elif [[ -n "$WAYBAR_OUTPUT_NAME" ]]; then
    echo "$WAYBAR_OUTPUT_NAME"
  else
    hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name'
  fi
}

# Convert monitor name to D-Bus object path segment (replace - with _)
get_dbus_name() {
  echo "${1//-/_}"
}

# Get state file for this monitor
get_state_file() {
  echo "${STATE_FILE_PREFIX}_${1}.tmp"
}

gammarelay_available() {
  busctl --user list 2>/dev/null | grep -q "rs\.wl-gammarelay"
}

# Set brightness via wl-gammarelay-rs D-Bus (value: 0-100)
set_brightness_gammarelay() {
  local monitor="$1"
  local brightness="$2"
  if ! gammarelay_available; then
    return 1
  fi
  local dbus_name
  dbus_name=$(get_dbus_name "$monitor")
  local value
  value=$(awk "BEGIN {printf \"%.2f\", $brightness / 100}")
  busctl --user set-property rs.wl-gammarelay "/outputs/$dbus_name" \
    rs.wl.gammarelay Brightness d "$value" 2>/dev/null
}

# Set laptop backlight brightness via brightnessctl (value: 0-100)
set_brightness_laptop() {
  brightnessctl set "${1}%" > /dev/null 2>&1
}

# Get current brightness for a monitor (returns 0-100 integer)
get_current_brightness() {
  local monitor="$1"
  local state_file
  state_file=$(get_state_file "$monitor")

  if [[ "$monitor" == "eDP-1" ]]; then
    if [[ ! -f "$state_file" ]]; then
      local current max percent
      current=$(brightnessctl get 2>/dev/null || echo "0")
      max=$(brightnessctl max 2>/dev/null || echo "1")
      percent=$(( current * 100 / max ))
      echo "$percent" > "$state_file"
    fi
    cat "$state_file"
  else
    # External monitor via wl-gammarelay-rs
    if ! gammarelay_available; then
      echo "?"
      return
    fi
    local dbus_name brightness
    dbus_name=$(get_dbus_name "$monitor")
    brightness=$(busctl --user get-property rs.wl-gammarelay "/outputs/$dbus_name" \
      rs.wl.gammarelay Brightness 2>/dev/null | awk '{printf "%d", $2 * 100}')
    if [[ -z "$brightness" ]]; then
      echo "?"
      return
    fi
    echo "$brightness" > "$state_file"
    echo "$brightness"
  fi
}

# Set brightness for a monitor and signal waybar
set_brightness() {
  local monitor="$1"
  local new_brightness="$2"
  local state_file
  state_file=$(get_state_file "$monitor")

  if [[ "$monitor" == "eDP-1" ]]; then
    echo "$new_brightness" > "$state_file"
    set_brightness_laptop "$new_brightness"
  else
    if set_brightness_gammarelay "$monitor" "$new_brightness"; then
      echo "$new_brightness" > "$state_file"
    else
      return 1
    fi
  fi

  pkill -RTMIN+8 waybar
}

COMMAND="$1"
MONITOR=$(get_monitor_name "$2")
current=$(get_current_brightness "$MONITOR")

case "$COMMAND" in
  "get")
    if [[ "$current" == "?" ]]; then
      echo " N/A"
    else
      echo " $current"
    fi
    ;;
  "up")
    if [[ "$current" == "?" ]]; then
      echo " N/A"
      exit 0
    fi
    new_brightness=$(( current + STEP > 100 ? 100 : current + STEP ))
    if (( current != new_brightness )); then
      set_brightness "$MONITOR" "$new_brightness"
    fi
    ;;
  "down")
    if [[ "$current" == "?" ]]; then
      echo " N/A"
      exit 0
    fi
    new_brightness=$(( current - STEP < 0 ? 0 : current - STEP ))
    if (( current != new_brightness )); then
      set_brightness "$MONITOR" "$new_brightness"
    fi
    ;;
  "right_click")
    if [[ "$current" == "?" ]]; then
      echo " N/A"
      exit 0
    fi
    set_brightness "$MONITOR" 0
    ;;
  "left_click")
    if [[ "$current" == "?" ]]; then
      echo " N/A"
      exit 0
    fi
    set_brightness "$MONITOR" 100
    ;;
esac
