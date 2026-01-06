#!/usr/bin/env bash
#
# zsh
source functions/_lib.sh

zsh_plugin_manager=zinit
zsh_path=$(command -v zsh)

if [ "$(basename "$SHELL")" != "zsh" ] && [ "${SKIP_SHELL_DETECT:-false}" == "false" ]; then
  info "changing to zsh shell ($zsh_path), please input password if nessesary"
  chsh -s "$zsh_path"
  success 'zsh changed'
fi

zsh_local_file=$DIRPATH/local.zsh
if ! [ -f "$zsh_local_file" ]; then
  cp "${zsh_local_file}.example" "$zsh_local_file"
fi

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
install_zinit () {
  info 'Install zinit'
  if ! [ -d ${ZINIT_HOME} ]; then
    mkdir -p "$(dirname $ZINIT_HOME)"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"

    success 'zinit installed'
  else
    success "skipped, zinit was installed"
  fi

  info 'Link zinit config'
  link_file "$DIRPATH/zinit.zsh" "$HOME/.zshrc"

  tips '=========Zinit========='
  tips 'please include zsh config: '
  tips ''
  tips '$ source ~/.zshrc'
  tips '$ zinit update --parallel'
  tips ''
  tips '==========================='

  # source "$HOME/.zshrc"
  # exec
  # zinit update --parallel
}

decrypt_zsh_local_file () {
  echo "Decrypt secrets zsh file ..."
  sops -d --input-type dotenv --output-type dotenv --age age10skqdpjag3uwnhdpeuvwlezc6wlwykdjzhhwqd9mvxvpcrw3gq8s0twla8 --pgp '' zsh/local.enc.zsh > zsh/local.zsh
}

install_zinit

if [ "${ZSH_DECRYPT_ENABLED:-false}" == "true" ]; then
  decrypt_zsh_local_file
fi
