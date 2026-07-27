#!/usr/bin/env bash
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
      printf "memory\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\n", mem_pct, mem_used / 1024 / 1024, mem_total / 1024 / 1024, swap_pct, swap_used / 1024 / 1024, swap_total / 1024 / 1024
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
if command -v nvidia-smi >/dev/null 2>&1; then
  gpu_line="$(nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu,name --format=csv,noheader,nounits 2>/dev/null | head -n 1 || true)"
  if [[ "${gpu_line:-}" =~ ^[[:space:]]*[0-9]+([.][0-9]+)?[[:space:]]*, ]]; then
    awk -F ', ' '{ printf "gpu\t%s\t%s\t%s\t%s\t%s\n", $1, $2, $3, $4, $5 }' <<<"$gpu_line"
    exit 0
  fi
fi

for busy_file in /sys/class/drm/card*/device/gpu_busy_percent; do
  if [ -r "$busy_file" ]; then
    device_dir="$(dirname "$busy_file")"
    busy="$(cat "$busy_file" 2>/dev/null || true)"
    name="$(awk -F= '/^DRIVER=/ { print $2; exit }' "$device_dir/uevent" 2>/dev/null || true)"
    printf "gpu\t%s\t\t\t\t%s\n" "${busy:-0}" "${name:-GPU}"
    exit 0
  fi
done

printf "gpu\t\t\t\t\tUnavailable\n"
