#!/usr/bin/env bash
#
# 链接 hypr-input-switcher 的配置文件

source functions/_lib.sh

dest_path="${HOME:-~}/.config/hypr-input-switcher"

mkdir -p $dest_path 2> /dev/null
link_file "${DIRPATH}/config.yaml" "${dest_path}/config.yaml"
