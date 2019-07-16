#!/usr/bin/env bash
#
# Tmux
source functions/_bash

tpm_path="$HOME/.tmux/plugins/tpm"
tpm_url="https://github.com/tmux-plugins/tpm"

if ! [ -d "$tpm_path" ]
then
    info " > Installing tpm"
    git clone $tpm_url $HOME/.tmux/plugins/tpm
    success "tpm"
fi
