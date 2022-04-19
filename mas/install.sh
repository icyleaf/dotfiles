#!/usr/bin/env bash
#
# Mac App Store

source functions/_lib.sh
ensure_macos

function login () {
  user "[Action request] login with App Store app please, choose action:\n\
        [l]og in, the other key to skip this?"
  read -n 1 action
  case "$action" in
    l )
      open -a "App Store"
      ;;
    * )
      ;;
  esac
}

info " > Installing Apps"

if test ! $(which mas); then
  fail "mas was not installed, run brew/install.sh to install first."
fi

installed_apps=`mas list`

for app in "PastePal" \
  "Amphetamine" \
  "Irvue" \
  "Hex Fiend" \
  "TweetDeck" \
  "MenubarX" \
  "CotEditor" \
  "DaisyDisk"; do

  if [ -z "$(ls /Applications | grep -i "$app")" ]; then
    mas lucky "$app"
  else
    echo "$app was installed"
  fi
done
success "MAS Apps"
