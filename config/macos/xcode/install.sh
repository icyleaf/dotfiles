#!/usr/bin/env bash
#
# xcode

source functions/_lib.sh

xcode_theme_name="Dracula.xccolortheme"
xcode_theme_path="${HOME:-~}/Library/Developer/Xcode/UserData/FontAndColorThemes"
xcode_theme_url=https://raw.githubusercontent.com/dracula/xcode/master/Dracula.xccolortheme

info "Installing Xcode Theme Dracula `pwd`"
if ! [ -f "$xcode_theme_path" ]; then
  mkdir -p $xcode_theme_path
  curl -sLf $xcode_theme_url  -o "${xcode_theme_path}/${xcode_theme_name}"

  success "Xcode Theme Dracula (Xcode restart required)"
else
  success "skipped, Xcode Theme was installed `pwd`"
fi
