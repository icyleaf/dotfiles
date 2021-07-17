#!/usr/bin/env bash
#
# 复制 karabiner-Elements 的配置文件

source functions/_lib.sh
ensure_macos

karabiner_install_path="${HOME:-~}/.config/karabiner"

info "Linking karabiner"
link_file "${DIRPATH}/assets/complex_modifications/60-keyboard.json" "${karabiner_install_path}/assets/complex_modifications/60-keyboard.json"
link_file "${DIRPATH}/karabiner.json" "${karabiner_install_path}/karabiner.json"
success "karabiner"
