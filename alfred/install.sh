#!/usr/bin/env bash
#
# 复制 alfred 的配置文件

if test ! "$(uname)" = "Darwin"; then
  exit 0
fi

source functions/_bash

overwrite= backup= skip=
action=

current_pwd=`pwd`
config_name="Alfred.alfredpreferences"
install_path="$HOME/Library/Application Support/Alfred/${config_name}"

info "Linking alfred `pwd`"
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
  link_file "${current_pwd}/alfred/Application Support/${config_name}" "$install_path"
  success "alfred"
fi

