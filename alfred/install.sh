#!/usr/bin/env bash
#
# 复制 alfred 的配置文件

source functions/_lib.sh
ensure_macos

alfred_name="Alfred.alfredpreferences"
alfred_dst="${HOME:-~}/Library/Application Support/Alfred"

if ! [ -d "$alfred_dst" ]; then
  mkdir $alfred_dst
  chmod 700 $alfred_dst
fi

link_file "${DIRPATH}/${alfred_name}" "$alfred_dst/${alfred_name}"
