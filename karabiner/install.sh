#!/usr/bin/env bash
#
# 复制 karabiner-Elements 的配置文件

if test ! "$(uname)" = "Darwin"; then
  exit 0
fi

source functions/_bash

karabiner_pwd=`pwd`
karabiner_install_path="$HOME/.config/karabiner"

info " > Linking karabiner `pwd`"
link_file "${karabiner_pwd}/karabiner/assets/complex_modifications/60-keyboard.json" "${karabiner_install_path}/assets/complex_modifications"
link_file "${karabiner_pwd}/karabiner/karabiner.json" "${karabiner_install_path}/karabiner.json"
success "karabiner"
