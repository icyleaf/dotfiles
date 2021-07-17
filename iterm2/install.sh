#!/usr/bin/env bash
#
# 复制 iterm2 的配置文件

source functions/_lib.sh
ensure_macos

iterm2_name="com.googlecode.iterm2.plist"
iterm2_dst="${HOME:-~}/Library/Preferences/${iterm2_name}"

link_file "${DIRPATH}/Preferences/${iterm2_name}" "$iterm2_dst"
