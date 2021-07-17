#!/usr/bin/env bash
#
# 复制 karabiner-Elements 的配置文件

source functions/_bash
ensure_macos

karabiner_pwd=`pwd`
karabiner_install_path="$HOME/.config/karabiner"

info " > Linking karabiner `pwd`"
link_file "${karabiner_pwd}/karabiner/assets/complex_modifications/60-keyboard.json" "${karabiner_install_path}/assets/complex_modifications"
link_file "${karabiner_pwd}/karabiner/karabiner.json" "${karabiner_install_path}/karabiner.json"
success "karabiner"
