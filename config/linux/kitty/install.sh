#!/usr/bin/env bash
#
# 链接 kitty 的配置文件

source functions/_lib.sh

dest_path="${HOME:-~}/.config/kitty"

mkdir -p $dest_path 2> /dev/null
link_file "${DIRPATH}/kitty.conf" "${dest_path}/kitty.conf"
link_file "${DIRPATH}/general.conf" "${dest_path}/general.conf"
link_file "${DIRPATH}/theme.conf" "${dest_path}/theme.conf"
link_file "${DIRPATH}/keybindings.conf" "${dest_path}/keybindings.conf"
