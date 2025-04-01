#!/usr/bin/env bash
#
# vim
source functions/_lib.sh

if test $(command -v nvim); then
  nvim_path="${HOME:-~}/.config/nvim"
  if ! [ -d "$nvim_path" ]; then
    git clone https://github.com/LazyVim/starter $nvim_path
  fi
  success "LazyVim"
else
  echo "Install neovim please"
fi
