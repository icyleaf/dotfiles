#!/usr/bin/env bash
#
# zsh
source functions/_lib.sh

omz_custom_path=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
powerlevel10k="powerlevel10k"
zsh_autosuggestions="zsh-autosuggestions"

if ! [ $SHELL == '/bin/zsh' ] && ! [ $SHELL == '/usr/local/bin/zsh' ]; then
  info 'changing to zsh shell. please input [sudo]'
  chsh -s /bin/zsh
  success 'zsh installed'
fi

zsh_local_file=$DIRPATH/local.zsh
if ! [ -f "$zsh_local_file" ]; then
  cp "${zsh_local_file}.example" "$zsh_local_file"
fi

if ! [ -d ${HOME:-~}/.oh-my-zsh ]; then
  info 'installing oh-my-zsh'
  git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh

  tips '=========Oh-My-Zsh========='
  tips 'please include zsh config: '
  tips ''
  tips '$ source ~/.zshrc '
  tips ''
  tips '==========================='
  success 'oh-my-zsh installed'
fi

if ! [ -d $omz_custom_path/themes/$powerlevel10k ]; then
  info "downloading ${powerlevel10k}"
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$omz_custom_path/themes/${powerlevel10k}"
  success "${powerlevel10k} downloaded"
fi

if ! [ -d $omz_custom_path/plugins/$zsh_autosuggestions ]; then
  info "downloading ${zsh_autosuggestions}"
  git clone https://github.com/zsh-users/zsh-autosuggestions "$omz_custom_path/plugins/${zsh_autosuggestions}"
  success "${zsh_autosuggestions} downloaded"
fi

# wakatime="wakatime"
# if ! [ -f $omz_custom_path/plugins/$wakatime ]; then
#   info "download ${wakatime}"
#   git clone https://github.com/sobolevn/wakatime-zsh-plugin.git "$omz_custom_path/plugins/${wakatime}"
#   success "${wakatime} downloaded"
# fi
