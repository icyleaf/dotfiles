#!/usr/bin/env bash
#
# 链接系统管理通用脚本

source functions/_lib.sh

ensure_local_bin
link_file "${DIRPATH}/bin/pm.sh" "${LOCAL_BIN_DIR}/pm.sh"
