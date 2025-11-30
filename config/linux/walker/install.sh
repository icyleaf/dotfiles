#!/usr/bin/env bash
#
# 链接 walker 的配置文件

source functions/_lib.sh

dest_path="${HOME:-~}/.config/walker"

mkdir -p $dest_path 2> /dev/null
link_file "${DIRPATH}/config.toml" "${dest_path}/config.toml"
link_file "${DIRPATH}/themes" "${dest_path}/themes"
