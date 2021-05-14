#!/usr/bin/env bash
#
# Mac App Store
source functions/_bash


function install_apps () {
  installed_apps=`mas list`

  for app in "PastePal" \
    "Sip" \
    "Amphetamine" \
    "Irvue" \
    "Hex Fiend" \
    "TweetDeck" \
    "DaisyDisk"; do

    no_installed=$(ls /Applications/ | grep -i "$app")
    if [ -z "$no_installed" ]; then
      mas lucky "$app"
    else
      echo "$app was installed"
    fi
  done
  success "MAS Apps"
}

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

mas account > /dev/null 2>&1
RESULT=$?
if ! [ $RESULT -eq 0 ]; then
  login
fi

install_apps
