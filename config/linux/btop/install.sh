#!/usr/bin/env bash
#
# 链接 btop 的配置文件

source functions/_lib.sh

dest_path="${HOME:-~}/.config/btop"

mkdir -p $dest_path 2> /dev/null
link_file "${DIRPATH}/btop.conf" "${dest_path}/btop.conf"
