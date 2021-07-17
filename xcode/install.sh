#!/usr/bin/env bash
#
# xcode

source functions/_bash
ensure_macos

xcode_theme_name="Dracula.xccolortheme"
xcode_theme_path="$HOME/Library/Developer/Xcode/UserData/FontAndColorThemes"
root_path=`pwd`

info " > Installing Xcode Theme Dracula `pwd`"
if ! [ -f "$xcode_theme_path" ]; then
  mkdir -p $xcode_theme_path
  curl -sLf https://raw.githubusercontent.com/dracula/xcode/master/Dracula.xccolortheme -o "${xcode_theme_path}/${xcode_theme_name}"

  cd $root_path
  success "Xcode Theme Dracula (Xcode restart required)"
else
  success "skipped, Xcode Theme was installed `pwd`"
fi
