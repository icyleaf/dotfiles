#!/usr/bin/env bash
#
# 链接系统管理通用脚本

source functions/_lib.sh

dest_path="${HOME:-~}/.local/bin"

mkdir -p $dest_path 2> /dev/null
link_file "${DIRPATH}/bin/pm.sh" "${dest_path}/pm.sh"
