#!/usr/bin/env bash
#
# vim
source functions/_bash

spacevim_path="$HOME/.SpaceVim"
spacevim_url="https://github.com/tmux-plugins/tpm"

info "Installing SpaceVim `pwd`"
if [ -z "$spacevim_path" ]
then
    curl -sLf https://spacevim.org/install.sh | bash
    success "spacvim"
else
    success "skipped, SpaceVim was installed `pwd`"
fi
