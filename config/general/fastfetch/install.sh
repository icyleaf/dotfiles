#!/usr/bin/env bash
#
# 链接 fastfetch 的配置文件

source functions/_lib.sh

dest_path="${HOME:-~}/.config/fastfetch"

link_file "${DIRPATH}" "$dest_path"
