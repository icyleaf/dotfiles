#!/usr/bin/env bash
#
# 初始化 Homebrew

if test ! $(which brew); then
  echo "  Installing Homebrew for you."

  # # 检查并安装 Homebrew
  if test "$(uname)" = "Darwin"; then
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

    # 替换为国内源
    cd "$(brew --repo)"
    git remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git

    cd "$(brew --repo)/Library/Taps/homebrew/homebrew-core"
    git remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git
  elif test "$(expr substr $(uname -s) 1 5)" = "Linux"; then
    # 安装 Linuxbrew
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install)"
  fi
fi