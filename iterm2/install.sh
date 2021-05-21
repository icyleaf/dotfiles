#!/usr/bin/env bash
#
# 复制 iterm2 的配置文件

source functions/_bash

overwrite= backup= skip=
action=

current_pwd=`pwd`
config_name="com.googlecode.iterm2.plist"
install_path="$HOME/Library/Preferences/${config_name}"

info "Linking iterm2 `pwd`"
if [ -f "$install_path" ]; then
  user "File already exists: $install_path, what do you want to do?\n\
        [s]kip, [o]verwrite, [b]ackup?"
        read -n 1 action

  case "$action" in
    o )
      overwrite=true;;
    b )
      backup=true;;
    s )
      skip=true;;
    * )
      ;;
  esac


  if [ "$overwrite" == "true" ]; then
    rm -rf "$install_path"
    success "removed $install_path"
  fi

  if [ "$backup" == "true" ]; then
    mv "$install_path" "${install_path}.backup"
    success "moved $install_path to ${install_path}.backup"
  fi

  if [ "$skip" == "true" ]; then
    success "skipped $config_name"
  fi
fi

if [ "$skip" != "true" ]; then  # "false" or empty
  link_file "${current_pwd}/iterm2/Preferences/${config_name}" "$install_path"
  success "iterm2"
fi

