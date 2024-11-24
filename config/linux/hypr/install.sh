#!/usr/bin/env bash
#
# 链接 hyprland 的配置文件

source functions/_lib.sh

dest_path="${HOME:-~}/.config/hypr"

mkdir -p $dest_path 2> /dev/null
link_file "${DIRPATH}/hypr" "${dest_path}/hypr"
link_file "${DIRPATH}/hyprland.conf" "${dest_path}/hyprland.conf"

