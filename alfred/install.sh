#!/usr/bin/env bash
#
# 复制 alfred 的配置文件

source functions/_bash
ensure_macos

current_pwd=`pwd`
config_name="Alfred.alfredpreferences"
install_path="$HOME/Library/Application Support/Alfred/${config_name}"

link_file "${current_pwd}/alfred/Application Support/${config_name}" "$install_path"
