#!/usr/bin/env bash
#
# xcode
source functions/_bash

xcode_theme_name="Dracula.xccolortheme"
xcode_theme_path="$HOME/Library/Developer/Xcode/UserData/FontAndColorThemes/${xcode_theme_name}"
xcode_theme_url="https://github.com/kreeger/base16-xcode"
root_path=`pwd`

info "Installing Xcode Theme `pwd`"
if ! [ -f "$xcode_theme_path" ]
then
    if [ -z "base16-xcode" ]
    then
      git clone $xcode_theme_url themes
      mv themes xcode
    fi

    link_file "${root_path}/xcode/themes/${xcode_theme_name}" $xcode_theme_path
    cd $root_path
    success "Xcode Theme"
else
    success "skipped, Xcode Theme was installed `pwd`"
fi
