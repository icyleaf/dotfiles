#!/usr/bin/env bash
#
# 链接 waybar 的配置文件

source functions/_lib.sh

dest_path="${HOME:-~}/.config/waybar"

mkdir -p $dest_path 2> /dev/null
link_file "${DIRPATH}/config.jsonc" "${dest_path}/config.jsonc"
link_file "${DIRPATH}/style.css" "${dest_path}/style.css"
link_file "${DIRPATH}/theme.css" "${dest_path}/theme.css"
