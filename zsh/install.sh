#!/usr/bin/env bash
#
# zsh
source functions/_bash

if ! [ $SHELL == '/bin/zsh' ] && ! [ $SHELL == '/usr/local/bin/zsh' ]; then
  info 'changing to zsh shell. please input [sudo]'
  sudo chsh -s /bin/zsh
  success 'zsh installed'
fi

if ! [ -d $HOME/.oh-my-zsh ]; then
  info 'git clone oh-my-zsh'
  git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
  success 'oh-my-zsh installed'

  tips '=========Oh-My-Zsh========='
  tips 'please include zsh config: '
  tips ''
  tips '$ source ~/.zshrc '
  tips ''
  tips '==========================='
fi

zsh_theme="bullet-train.zsh-theme"
if ! [ -f $HOME/.oh-my-zsh/themes/$zsh_theme ]; then
  info 'download ${zsh_theme}'
  curl -L http://raw.github.com/caiogondim/bullet-train-oh-my-zsh-theme/master/${zsh_theme} -o ~/.oh-my-zsh/themes/${zsh_theme}
  success '${zsh_theme} downloaded'
fi
