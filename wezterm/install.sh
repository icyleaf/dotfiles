#!/usr/bin/env bash
#
# 链接 wezterm 的配置文件

source functions/_lib.sh

sources_path="config"
dest_path="${HOME:-~}/.config/wezterm"

mkdir -p $dest_path 2> /dev/null
link_file "${DIRPATH}/config" "${dest_path}/config"
link_file "${DIRPATH}/wezterm.lua" "${dest_path}/wezterm.lua"

