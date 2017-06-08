#!/usr/bin/env bash
#
# 初始化 Homebrew

# 检查并安装 Homebrew
if test ! $(which brew)
then
  ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"
fi

# 替换为国内源
cd "$(brew --repo)"
git remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git

cd "$(brew --repo)/Library/Taps/homebrew/homebrew-core"
git remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git

# 安装 Homebrew Taps
brew tap caskroom/fonts
brew tap homebrew/services