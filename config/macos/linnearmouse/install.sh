#!/usr/bin/env bash
#
# 复制 linnearMouse 的配置文件

source functions/_lib.sh

linearmouse_name="com.lujjjh.LinearMouse.plist"
linearmouse_dst="${HOME:-~}/Library/Preferences/${linearmouse_name}"

link_file "${DIRPATH}/Preferences/${linearmouse_name}" "$linearmouse_dst"
