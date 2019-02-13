#!/usr/bin/env bash
#
# homebrew

source functions/_bash

brew_path=`pwd`

info "Installing homebrew"
if test ! $(which brew); then
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

    # 替换为国内源
    cd "$(brew --repo)"
    git remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git

    cd "$(brew --repo)/Library/Taps/homebrew/homebrew-core"
    git remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git

    cd $brew_path
    brew update --rebase

    success "homebrew"

    # 安装 Brewfile 里面的内容
    info "Installing bundle"
    brew bundle -v
    success "brew bundle"
else
    success "skipped, homebrew was installed `pwd`"
fi
