#!/usr/bin/env bash
# This script collects system status information including host, uptime, CPU, memory, load average, disk usage, GPU status, and CPU details.
# Copy from https://github.com/AyushKr2003/omarchy-dotfiles
# Copyright (c) Ayush Kumar

set -uo pipefail

disk_path="${1:-/}"

# Host & Uptime Info
uptime_sec="$(awk '{print int($1)}' /proc/uptime 2>/dev/null || echo 0)"
uptime_hrs=$((uptime_sec / 3600))
uptime_mins=$(((uptime_sec % 3600) / 60))
if [ "$uptime_hrs" -gt 0 ]; then
  uptime_str="${uptime_hrs}h ${uptime_mins}m"
else
  uptime_str="${uptime_mins}m"
fi
kernel_str="$(uname -r 2>/dev/null || echo 'Linux')"
host_name="$(hostname 2>/dev/null || echo 'localhost')"
printf "host\t%s\t%s\t%s\n" "$host_name" "$kernel_str" "$uptime_str"

# CPU Info
awk '
  NR == 1 {
    idle = $5
    total = 0
    for (i = 2; i <= NF; i++) total += $i
    cores = 0
    while ((getline line < "/proc/cpuinfo") > 0) {
      if (line ~ /^processor[[:space:]]*:/) cores++
    }
    close("/proc/cpuinfo")
    if (cores < 1) cores = 1
    printf "cpu\t%s\t%s\t%s\n", idle, total, cores
  }
' /proc/stat

# Memory & Swap Info
awk '
  /^MemTotal:/ { mem_total = $2 }
  /^MemAvailable:/ { mem_avail = $2 }
  /^SwapTotal:/ { swap_total = $2 }
  /^SwapFree:/ { swap_free = $2 }
  END {
    if (mem_total > 0) {
      mem_used = mem_total - mem_avail
      mem_pct = (mem_used / mem_total) * 100
      swap_used = swap_total - swap_free
      swap_pct = swap_total > 0 ? (swap_used / swap_total) * 100 : 0
      printf "memory\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%d\t%d\n", mem_pct, mem_used / 1024 / 1024, mem_total / 1024 / 1024, swap_pct, swap_used / 1024 / 1024, swap_total / 1024 / 1024, mem_total, mem_avail
    }
  }
' /proc/meminfo

# Load Average
awk '{ printf "load\t%s\t%s\t%s\n", $1, $2, $3 }' /proc/loadavg

# Disk Info
df -P -B1 "$disk_path" 2>/dev/null | awk 'NR == 2 {
  used = $3
  total = $2
  pct = total > 0 ? (used / total) * 100 : 0
  printf "disk\t%.2f\t%.2f\t%.2f\t%s\n", pct, used / 1024 / 1024 / 1024, total / 1024 / 1024 / 1024, $6
}'

# GPU Info
gpu_printed=0
if command -v nvidia-smi >/dev/null 2>&1; then
  gpu_line="$(nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu,name --format=csv,noheader,nounits 2>/dev/null | head -n 1 || true)"
  if [[ "${gpu_line:-}" =~ ^[[:space:]]*[0-9]+([.][0-9]+)?[[:space:]]*, ]]; then
    awk -F ', ' '{ printf "gpu\t%s\t%s\t%s\t%s\t%s\n", $1, $2, $3, $4, $5 }' <<<"$gpu_line"
    gpu_printed=1
  fi
fi

if [ "$gpu_printed" -eq 0 ]; then
  for busy_file in /sys/class/drm/card*/device/gpu_busy_percent; do
    if [ -r "$busy_file" ]; then
      device_dir="$(dirname "$busy_file")"
      busy="$(cat "$busy_file" 2>/dev/null || true)"
      name="$(awk -F= '/^DRIVER=/ { print $2; exit }' "$device_dir/uevent" 2>/dev/null || true)"
      printf "gpu\t%s\t\t\t\t%s\n" "${busy:-0}" "${name:-GPU}"
      gpu_printed=1
      break
    fi
  done
fi

if [ "$gpu_printed" -eq 0 ]; then
  printf "gpu\t\t\t\t\tUnavailable\n"
fi

# CPU Extra Details: Temp, Max Freq, Cur Freq, Model Name
cpu_temp=$(sensors 2>/dev/null | awk 'BEGIN { first = 1 } /^Package id 0:|^Tctl:|^temp1:/ { if (first) { if (match($0, /[+]?[0-9]+(\.[0-9]+)?/)) { value = substr($0, RSTART, RLENGTH); sub(/^\+/, "", value); sub(/\..*/, "", value); print value; first = 0 } } }' 2>/dev/null || echo 0)
cpu_max_mhz=$(awk '{printf "%.0f\n", $1/1000}' /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq 2>/dev/null || echo 0)
cpu_cur_mhz=$(awk '{sum+=$1; count++} END {if (count>0) printf "%.0f\n", sum/count/1000}' /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq 2>/dev/null || echo 0)
cpu_model=$(awk -F: '/model name/ { gsub(/^[ \t]+|[ \t]+$/, "", $2); sub(/ CPU.*/, "", $2); print $2; exit }' /proc/cpuinfo 2>/dev/null || echo "")

printf "cpu_detail\t%s\t%s\t%s\t%s\n" "${cpu_temp:-0}" "${cpu_max_mhz:-0}" "${cpu_cur_mhz:-0}" "${cpu_model:-}"

# Thermal sensors: every readable hwmon temp*_input as a JSON array.
# Grouping/per-core collapsing happens in the panel, not here.
sensors_json="["
sensor_first=1
for hwmon in /sys/class/hwmon/hwmon*; do
  [ -d "$hwmon" ] || continue
  sensor_source="hwmon"
  [ -f "$hwmon/name" ] && sensor_source=$(cat "$hwmon/name" 2>/dev/null) && [ -n "$sensor_source" ] || sensor_source="hwmon"
  for temp_file in "$hwmon"/temp*_input; do
    [ -f "$temp_file" ] || continue
    raw=$(cat "$temp_file" 2>/dev/null || true)
    [ -z "$raw" ] && continue
    temp_c=$((raw / 1000))
    [ "$temp_c" -le 0 ] && continue
    [ "$temp_c" -gt 200 ] && continue
    sensor_index="${temp_file##*temp}"
    sensor_index="${sensor_index%%_input*}"
    label_file="${hwmon}/temp${sensor_index}_label"
    sensor_label=""
    [ -f "$label_file" ] && sensor_label=$(cat "$label_file" 2>/dev/null || true)
    [ -z "$sensor_label" ] && sensor_label="Sensor ${sensor_index}"
    sensor_label=${sensor_label//\\/}
    sensor_label=${sensor_label//\"/}
    [ "$sensor_first" -eq 1 ] || sensors_json="${sensors_json},"
    sensor_first=0
    sensors_json="${sensors_json}{\"source\":\"${sensor_source}\",\"label\":\"${sensor_label}\",\"temp\":${temp_c}}"
  done
done
sensors_json="${sensors_json}]"
printf "temps\t%s\n" "$sensors_json"

# Fans: every spinning hwmon fan*_input as a JSON array.
fans_json="["
fan_first=1
for hwmon in /sys/class/hwmon/hwmon*; do
  [ -d "$hwmon" ] || continue
  fan_source="hwmon"
  [ -f "$hwmon/name" ] && fan_source=$(cat "$hwmon/name" 2>/dev/null) && [ -n "$fan_source" ] || fan_source="hwmon"
  for fan_file in "$hwmon"/fan*_input; do
    [ -f "$fan_file" ] || continue
    rpm=$(cat "$fan_file" 2>/dev/null || true)
    [ -z "$rpm" ] && continue
    [ "$rpm" -eq 0 ] 2>/dev/null && continue
    fan_index="${fan_file##*fan}"
    fan_index="${fan_index%%_input*}"
    label_file="${hwmon}/fan${fan_index}_label"
    fan_label=""
    [ -f "$label_file" ] && fan_label=$(cat "$label_file" 2>/dev/null || true)
    [ -z "$fan_label" ] && fan_label="Fan ${fan_index}"
    fan_label=${fan_label//\\/}
    fan_label=${fan_label//\"/}
    [ "$fan_first" -eq 1 ] || fans_json="${fans_json},"
    fan_first=0
    fans_json="${fans_json}{\"source\":\"${fan_source}\",\"label\":\"${fan_label}\",\"rpm\":${rpm}}"
  done
done
fans_json="${fans_json}]"
printf "fans\t%s\n" "$fans_json"
