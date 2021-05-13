#!/usr/bin/env bash
#
# homebrew

source functions/_bash

brew_path=`pwd`

export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
# export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"

info " > Installing homebrew"
if test ! $(which brew); then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # 安装 tap
  brew tap homebrew/cask-fonts

  # 替换为国内源
  git -C "$(brew --repo)" remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git
  BREW_TAPS="$(brew tap)"
  for tap in core services cask{,-fonts}; do
    if echo "$BREW_TAPS" | grep -qE "^homebrew/${tap}\$"; then
      git -C "$(brew --repo homebrew/${tap})" remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-${tap}.git
      git -C "$(brew --repo homebrew/${tap})" config homebrew.forceautoupdate true
    fi
  done

  cd $brew_path
  brew update-reset

  success "homebrew"
else
  success "skipped, homebrew was installed `pwd`"
fi

# 安装 Brewfile 里面的内容
info "Installing brew bundle"
cd "${brew_path}/brew"
brew bundle -v
success "brew bundle"
