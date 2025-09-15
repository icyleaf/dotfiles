#!/usr/bin/env bash
#
# 链接 swaync 的配置文件

source functions/_lib.sh

dest_path="${HOME:-~}/.config/swaync"

mkdir -p $dest_path 2> /dev/null
link_file "${DIRPATH}/config.json" "${dest_path}/config.json"
