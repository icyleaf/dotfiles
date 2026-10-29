#!/usr/bin/env bash
# This script collects system status information including host, uptime, CPU, memory, load average, disk usage, GPU status, and CPU details.
# Copyright (c) Ayush Kumar, modified and optimized for omarchy by icyleaf

set -uo pipefail

disk_path="${1:-/}"

# Host & Uptime Info
read -r uptime_raw _ < /proc/uptime 2>/dev/null || uptime_raw="0"
uptime_sec="${uptime_raw%%.*}"
uptime_hrs=$((uptime_sec / 3600))
uptime_mins=$(((uptime_sec % 3600) / 60))
if [ "$uptime_hrs" -gt 0 ]; then
  uptime_str="${uptime_hrs}h ${uptime_mins}m"
else
  uptime_str="${uptime_mins}m"
fi
kernel_str="$(uname -r 2>/dev/null || echo 'Linux')"
host_name="${HOSTNAME:-localhost}"
printf "host\t%s\t%s\t%s\n" "$host_name" "$kernel_str" "$uptime_str"

# CPU Info
awk '
  NR == 1 {
    idle = $5
    total = 0
    for (i = 2; i <= NF; i++) total += $i
    next
  }
  /^cpu[0-9]/ { cores++ }
  END {
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
read -r l1 l5 l15 _ < /proc/loadavg
printf "load\t%s\t%s\t%s\n" "$l1" "$l5" "$l15"

# Disk Info
df -P -B1 "$disk_path" 2>/dev/null | awk 'NR == 2 {
  used = $3
  total = $2
  pct = total > 0 ? (used / total) * 100 : 0
  printf "disk\t%.2f\t%.2f\t%.2f\t%s\n", pct, used / 1024 / 1024 / 1024, total / 1024 / 1024 / 1024, $6
}'

# GPU Info (Device-guarded: only call nvidia-smi if active NVIDIA character device exists)
gpu_printed=0
if [ -c /dev/nvidiactl ] && command -v nvidia-smi >/dev/null 2>&1; then
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
      read -r busy < "$busy_file" 2>/dev/null || busy=0
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

# Thermal sensors & CPU details (Direct sysfs read; single-pass across /sys/class/hwmon)
cpu_temp=0
sensors_json="["
sensor_first=1
fans_json="["
fan_first=1

for hwmon in /sys/class/hwmon/hwmon*; do
  [ -d "$hwmon" ] || continue
  hwmon_name="hwmon"
  if [ -r "$hwmon/name" ]; then
    read -r hwmon_name < "$hwmon/name" 2>/dev/null || hwmon_name="hwmon"
  fi

  # For nvme devices, read composite temp1_input only to avoid repeated PCIe SMART queries
  if [ "$hwmon_name" = "nvme" ]; then
    temp_files=("$hwmon/temp1_input")
  else
    temp_files=("$hwmon"/temp*_input)
  fi

  for temp_file in "${temp_files[@]}"; do
    [ -f "$temp_file" ] || continue
    read -r raw < "$temp_file" 2>/dev/null || continue
    [ -z "$raw" ] && continue
    temp_c=$((raw / 1000))
    [ "$temp_c" -le 0 ] && continue
    [ "$temp_c" -gt 200 ] && continue

    case "$hwmon_name" in
      k10temp|coretemp|zenpower)
        [ "$cpu_temp" -eq 0 ] && cpu_temp=$temp_c
        ;;
      acpitz)
        [ "$cpu_temp" -eq 0 ] && cpu_temp=$temp_c
        ;;
    esac

    sensor_index="${temp_file##*temp}"
    sensor_index="${sensor_index%%_input*}"
    label_file="${hwmon}/temp${sensor_index}_label"
    sensor_label=""
    if [ -r "$label_file" ]; then
      read -r sensor_label < "$label_file" 2>/dev/null || true
    fi
    [ -z "$sensor_label" ] && sensor_label="Sensor ${sensor_index}"
    sensor_label=${sensor_label//\\/}
    sensor_label=${sensor_label//\"/}
    [ "$sensor_first" -eq 1 ] || sensors_json="${sensors_json},"
    sensor_first=0
    sensors_json="${sensors_json}{\"source\":\"${hwmon_name}\",\"label\":\"${sensor_label}\",\"temp\":${temp_c}}"
  done

  for fan_file in "$hwmon"/fan*_input; do
    [ -f "$fan_file" ] || continue
    read -r rpm < "$fan_file" 2>/dev/null || continue
    [ -z "$rpm" ] && continue
    [ "$rpm" -eq 0 ] 2>/dev/null && continue
    fan_index="${fan_file##*fan}"
    fan_index="${fan_index%%_input*}"
    label_file="${hwmon}/fan${fan_index}_label"
    fan_label=""
    if [ -r "$label_file" ]; then
      read -r fan_label < "$label_file" 2>/dev/null || true
    fi
    [ -z "$fan_label" ] && fan_label="Fan ${fan_index}"
    fan_label=${fan_label//\\/}
    fan_label=${fan_label//\"/}
    [ "$fan_first" -eq 1 ] || fans_json="${fans_json},"
    fan_first=0
    fans_json="${fans_json}{\"source\":\"${hwmon_name}\",\"label\":\"${fan_label}\",\"rpm\":${rpm}}"
  done
done
sensors_json="${sensors_json}]"
fans_json="${fans_json}]"

read -r max_freq < /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq 2>/dev/null || max_freq=0
cpu_max_mhz=$((max_freq / 1000))

cur_sum=0
cur_cnt=0
for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq; do
  [ -f "$f" ] || continue
  read -r cf < "$f" 2>/dev/null || continue
  cur_sum=$((cur_sum + cf))
  ((cur_cnt++))
done
cpu_cur_mhz=$((cur_cnt > 0 ? cur_sum / cur_cnt / 1000 : 0))

cpu_model=$(awk -F: '/model name/ { gsub(/^[ \t]+|[ \t]+$/, "", $2); sub(/ CPU.*/, "", $2); print $2; exit }' /proc/cpuinfo 2>/dev/null || echo "")

printf "cpu_detail\t%s\t%s\t%s\t%s\n" "${cpu_temp:-0}" "${cpu_max_mhz:-0}" "${cpu_cur_mhz:-0}" "${cpu_model:-}"
printf "temps\t%s\n" "$sensors_json"
printf "fans\t%s\n" "$fans_json"
