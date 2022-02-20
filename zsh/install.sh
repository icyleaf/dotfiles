#!/usr/bin/env bash
#
# zsh
source functions/_lib.sh

zsh_plugin_manager=zinit

if ! [ $SHELL == '/bin/zsh' ] && ! [ $SHELL == '/usr/local/bin/zsh' ]; then
  info 'changing to zsh shell. please input [sudo]'
  chsh -s /bin/zsh
  success 'zsh installed'
fi

zsh_local_file=$DIRPATH/local.zsh
if ! [ -f "$zsh_local_file" ]; then
  cp "${zsh_local_file}.example" "$zsh_local_file"
fi

choose_zsh_plugin_manager () {
  user "Which zsh plugin manager do you want to use?\n\
        1 [o]h-my-zsh\n\
        2 [z]init"
  read -n 1 zsh_plugin_manager
  echo ""
  case "$zsh_plugin_manager" in
    1|o|O )
      install_omz
      ;;
    2|z|Z )
      install_zinit
      ;;
    * )
      warn "Do not detch any zsh plugin manager, try again!"
      choose_zsh_plugin_manager
      ;;
  esac
}

install_omz () {
  local omz_custom_path=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
  local powerlevel10k="powerlevel10k"
  local zsh_autosuggestions="zsh-autosuggestions"

  info 'Install oh-my-zsh'
  if ! [ -d ${HOME:-~}/.oh-my-zsh ]; then
    git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh

    tips '=========Oh-My-Zsh========='
    tips 'please include zsh config: '
    tips ''
    tips '$ source ~/.zshrc '
    tips ''
    tips '==========================='
    success 'oh-my-zsh installed'
  else
    success "skipped, oh-my-zsh was installed"
  fi

  if ! [ -d $omz_custom_path/themes/$powerlevel10k ]; then
    info "Download ${powerlevel10k}"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$omz_custom_path/themes/${powerlevel10k}"
    success "${powerlevel10k} downloaded"
  fi

  if ! [ -d $omz_custom_path/plugins/$zsh_autosuggestions ]; then
    info "Download ${zsh_autosuggestions}"
    git clone https://github.com/zsh-users/zsh-autosuggestions "$omz_custom_path/plugins/${zsh_autosuggestions}"
    success "${zsh_autosuggestions} downloaded"
  fi

  # wakatime="wakatime"
  # if ! [ -f $omz_custom_path/plugins/$wakatime ]; then
  #   info "download ${wakatime}"
  #   git clone https://github.com/sobolevn/wakatime-zsh-plugin.git "$omz_custom_path/plugins/${wakatime}"
  #   success "${wakatime} downloaded"
  # fi

  info 'Link omz config'
  link_file "$DIRPATH/omz.zsh" "$HOME/.zshrc"
}

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
install_zinit () {
  info 'Install zinit'
  if ! [ -d ${ZINIT_HOME} ]; then
    mkdir -p "$(dirname $ZINIT_HOME)"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"

    tips '=========Zinit========='
    tips 'please include zsh config: '
    tips ''
    tips '$ source ~/.zshrc '
    tips ''
    tips '==========================='
    success 'zinit installed'
  else
    success "skipped, zinit was installed"
  fi

  info 'Link zinit config'
  link_file "$DIRPATH/zinit.zsh" "$HOME/.zshrc"

  source "$HOME/.zshrc"
  zinit update --parallel

  # wakatime="wakatime"
  # if ! [ -f $omz_custom_path/plugins/$wakatime ]; then
  #   info "download ${wakatime}"
  #   git clone https://github.com/sobolevn/wakatime-zsh-plugin.git "$omz_custom_path/plugins/${wakatime}"
  #   success "${wakatime} downloaded"
  # fi

}

choose_zsh_plugin_manager
