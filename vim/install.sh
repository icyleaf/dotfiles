#!/usr/bin/env bash
#
# vim
source functions/_lib.sh

spacevim_path="${HOME:-~}/.SpaceVim"
spacevim_url="https://spacevim.org/install.sh"

info "Installing SpaceVim `pwd`"
if ! [ -d "$spacevim_path" ]; then
  curl -sLf $spacevim_url | bash
  success "spacvim"
else
  success "skipped, SpaceVim was installed `pwd`"
fi
