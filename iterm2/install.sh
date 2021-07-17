#!/usr/bin/env bash
#
# 复制 iterm2 的配置文件

source functions/_lib.sh
ensure_macos

config_name="com.googlecode.iterm2.plist"
install_path="${HOME:-~}/Library/Preferences/${config_name}"

link_file "${DIRPATH}/Preferences/${config_name}" "$install_path"
