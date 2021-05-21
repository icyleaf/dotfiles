#!/usr/bin/env bash
#
# zsh
source functions/_bash

if ! [ $SHELL == '/bin/zsh' ] && ! [ $SHELL == '/usr/local/bin/zsh' ]; then
  info 'changing to zsh shell. please input [sudo]'
  chsh -s /bin/zsh
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

omz_custom_path=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
root_path=`pwd`

zsh_theme="bullet-train.zsh-theme"
if ! [ -f $omz_custom_path/themes/$zsh_theme ]; then
  info "download ${zsh_theme}"
  curl -sLf http://raw.github.com/caiogondim/bullet-train-oh-my-zsh-theme/master/${zsh_theme} -o "$omz_custom_path/themes/${zsh_theme}"
  success "${zsh_theme} downloaded"
fi

zsh_autosuggestions="zsh-autosuggestions"
if ! [ -f $omz_custom_path/plugins/$zsh_autosuggestions ]; then
  info "download ${zsh_autosuggestions}"
  git clone https://github.com/zsh-users/zsh-autosuggestions "$omz_custom_path/plugins/${zsh_autosuggestions}"
  success "${zsh_autosuggestions} downloaded"
fi

powerlevel10k="powerlevel10k"
if ! [ -f $omz_custom_path/themes/$powerlevel10k ]; then
  info "download ${powerlevel10k}"
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$omz_custom_path/themes/${powerlevel10k}"
  success "${powerlevel10k} downloaded"
fi
