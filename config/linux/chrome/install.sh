#!/usr/bin/env bash
#
# 链接 htop 的配置文件

source functions/_lib.sh

link_file "${DIRPATH}/chrome-flags.conf" "${HOME:-~}/.config/chrome-flags.conf"

