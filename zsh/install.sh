#!/usr/bin/env bash
#
# Oh-My-Zsh
source functions/_bash

if ! [ "$(echo $SHELL)" == '/bin/zsh' ]
then
  info 'changing to zsh shell. please input [sudo]'
  sudo chsh -s /bin/zsh
  success 'zsh installed'
fi

if ! [ -d ~/.oh-my-zsh ]
then
  info 'git clone oh-my-zsh'
  git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
  success 'oh-my-zsh installed'
fi

if ! [ -f ~/.oh-my-zsh/themes/icyleaf.zsh-theme ]
then
  info 'download icyleaf.zsh-theme'
  curl -L https://gist.github.com/icyleaf/1016181/raw/d16f05c900e33178a03693c1454c3b5e64bf3b80/icyleaf.zsh-theme -o ~/.oh-my-zsh/themes/icyleaf.zsh-theme
  success 'icyleaf.zsh-theme downloaded'
fi

success 'zsh installed'

tips '=========Oh-My-Zsh========='
tips 'please include zsh config: '
tips ''
tips '$ source ~/.zshrc '
tips ''
tips '==========================='