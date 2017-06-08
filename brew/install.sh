#!/usr/bin/env bash
#
# Install apps using brew
source functions/_bash


brew_install() {
  RESULT=$(brew ls --versions ${1})
  NAME=$(echo ${RESULT} | awk '{print $1}')
  VERSION=$(echo ${RESULT} | awk '{print $2}')

  if test ! ${NAME}
  then
    info "Installing ${1}"
    brew install ${1}
    success "Installed ${1}"
  else
    success "${1} already installed: ${VERSION}"
  fi
}

# DevOps
brew_install ansible

# Git
brew_install git
brew_install git-flow-avh
# brew_install tig

# Development Tools
brew_install mysql
brew_install mycli
brew_install redis
brew_install node
brew_install imagemagick

# Development Language
brew_install crystal-lang

# Tweaks
brew_install fasd
brew_install axel
brew_install mtr
brew_install tree
brew_install watch
brew_install wget
brew_install ssh-copy-id
brew_install youtube-dl
brew_install httpie
brew_install mobile-shell
brew_install mitmproxy
brew_install hugo

# Tmux
brew_install tmux
brew_install reattach-to-user-namespace

# macOS Apps
brew cask install visual-studio-code
brew cask install google-chrome
brew cask install iterm2
brew cask install the-unarchiver
brew cask install dropbox
brew cask install android-sdk
brew cask install virtualbox
# brew cask install android-studio

# macOS QuickLook Extensions
brew cask isntall provisionql
brew cask isntall qlcolorcode
brew cask isntall qlimagesize
brew cask isntall quicklook-json
brew cask isntall quicklookapk
