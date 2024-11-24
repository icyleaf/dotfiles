#!/usr/bin/env bash
#
# 链接 helix 的配置文件

source functions/_lib.sh
ensure_macos

source_path="config"
dest_path="${HOME:-~}/.config/helix"

link_file "${DIRPATH}/${source_path}" "$dest_path"
