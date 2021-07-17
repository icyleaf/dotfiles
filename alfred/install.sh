#!/usr/bin/env bash
#
# 复制 alfred 的配置文件

source functions/_lib.sh
ensure_macos

local config_name="Alfred.alfredpreferences"
local install_path="${HOME:-~}/Library/Application Support/Alfred/${config_name}"

link_file "${DIRPATH}/Application Support/${config_name}" "$install_path"
