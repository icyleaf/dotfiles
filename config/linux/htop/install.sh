#!/usr/bin/env bash
#
# 链接 htop 的配置文件

source functions/_lib.sh

dest_path="${HOME:-~}/.config/htop"

mkdir -p $dest_path 2> /dev/null
link_file "${DIRPATH}/htoprc" "${dest_path}/htoprc"

