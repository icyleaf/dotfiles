#!/usr/bin/env bash
#
# Init homebrew 

# Install homebrew if not exists
if test ! $(which brew)
then
  ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"
fi

# Install native apps
if test ! $(brew list | grep brew-cask)
then
  brew tap phinze/homebrew-cask
  brew install brew-cask
fi