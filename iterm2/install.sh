#!/usr/bin/env bash
#
# 复制 iterm2 的配置文件

source functions/_bash

current_pwd=`pwd`
install_path="$HOME/Library/Preferences/"

info "Linking iterm2 `pwd`"
link_file "${current_pwd}/iterm2/Preferences/com.googlecode.iterm2.plist" "${install_path}/com.googlecode.iterm2.plist"
success "iterm2"

# TODO: how to install theme in terminal?

