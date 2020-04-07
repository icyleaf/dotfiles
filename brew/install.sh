#!/usr/bin/env bash
#
# homebrew

source functions/_bash

brew_path=`pwd`

info "Installing homebrew"
if test ! $(which brew); then
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

    # 替换为国内源
    git -C "$(brew --repo)" remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git
    git -C "$(brew --repo homebrew/core)" remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git
    git -C "$(brew --repo homebrew/cask)" remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-cask.git
    git -C "$(brew --repo homebrew/cask-fonts)" remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-cask-fonts.git

    cd $brew_path
    brew update --verbose

    success "homebrew"
else
    success "skipped, homebrew was installed `pwd`"
fi

# 安装 Brewfile 里面的内容
info "Installing brew bundle"
cd "${brew_path}/brew"
brew bundle -v
success "brew bundle"
