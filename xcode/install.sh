#!/usr/bin/env bash
#
# xcode

if test ! "$(uname)" = "Darwin"; then
  exit 0
fi

source functions/_bash

xcode_theme_name="Dracula.xccolortheme"
xcode_theme_path="$HOME/Library/Developer/Xcode/UserData/FontAndColorThemes/${xcode_theme_name}"
root_path=`pwd`

info " > Installing Xcode Theme Dracula `pwd`"
if ! [ -f "$xcode_theme_path" ]; then
  curl -sLf https://raw.githubusercontent.com/dracula/xcode/master/Dracula.xccolortheme -o $xcode_theme_path

  cd $root_path
  success "Xcode Theme Dracula"
else
  success "skipped, Xcode Theme was installed `pwd`"
fi
