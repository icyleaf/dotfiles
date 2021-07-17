#!/usr/bin/env bash
#
# 复制 alfred 的配置文件

source functions/_lib.sh
ensure_macos

alfred_name="Alfred.alfredpreferences"
alfred_dst="${HOME:-~}/Library/Application Support/Alfred/${alfred_name}"

link_file "${DIRPATH}/${alfred_name}" "$alfred_dst"
