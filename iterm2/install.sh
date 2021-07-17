#!/usr/bin/env bash
#
# 复制 iterm2 的配置文件

source functions/_bash
ensure_macos

current_pwd=`pwd`
config_name="com.googlecode.iterm2.plist"
install_path="$HOME/Library/Preferences/${config_name}"

link_file "${current_pwd}/iterm2/Preferences/${config_name}" "$install_path"
