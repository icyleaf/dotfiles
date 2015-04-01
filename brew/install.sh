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

##################
# Command tools
##################

# DevOpt
brew_install ansible

# Git
brew_install hub
brew_install git
brew_install git-flow

# Development Tools
brew_install android-sdk
brew_install mysql
brew_install nginx
brew_install redis
brew_install postgresql
brew_install ios-sim
brew_install appledoc
brew_install emacs

# Development Language
brew_install go

# Tweaks
brew_install autojump
brew_install axel
brew_install mtr
brew_install tree
brew_install watch
brew_install wget
brew_install xtail
brew_install multitail
brew_install osxutils
brew_install ssh-copy-id
brew_install youtube-dl

# Tmux 
brew_install tmux
brew_install reattach-to-user-namespace


##################
# Apps
##################
# brew cask install alfred
# brew cask install android-studio
# brew cask install vagrant
# brew cask install dropbox
# brew cask install google-chrome
# brew cask install google-chrome-canary
# brew cask install iterm2
# brew cask install miro-video-converter
# brew cask install sublime-text
# brew cask install the-unarchiver
# brew cask install virtualbox
# brew cask install vlc
