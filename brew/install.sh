#!/usr/bin/env bash
#
# 初始化 Homebrew

source functions/_bash

brew_path=`pwd`
if test ! $(which brew); then
  # # 检查并安装 Homebrew
  if test "$(uname)" = "Darwin"; then
    echo " > Installing Homebrew for you."
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

    # 替换为国内源
    cd "$(brew --repo)"
    git remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git

    cd "$(brew --repo)/Library/Taps/homebrew/homebrew-core"
    git remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git

    cd $brew_path
    brew update

    # 安装 Brewfile 里面的内容
    echo "› Install  bundle"
    brew bundle -v
  elif test "$(expr substr $(uname -s) 1 5)" = "Linux"; then
    # 安装 Linuxbrew
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install)"
  fi
else
  success "skip"
fi
