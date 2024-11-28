#!/usr/bin/env bash
#
# vim
source functions/_lib.sh

if test $(command -v nvim); then
  nvim_path="${HOME:-~}/.config/nvim"
  if ! [ -d "$spacevim_path" ]; then
    git clone https://github.com/LazyVim/starter $nvim_path
  fi
  success "LazyVim"
elif test $(command -v vim); then
  spacevim_path="${HOME:-~}/.SpaceVim"
  if ! [ -d "$spacevim_path" ]; then
    curl -sLf https://spacevim.org/install.sh | bash
  fi
  success "SpaceVim"
end
