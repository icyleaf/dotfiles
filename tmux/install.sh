#!/usr/bin/env bash
#
# Tmux
source functions/_lib.sh

tpm_path="${HOME:-~}/.tmux/plugins/tpm"
tpm_url="https://github.com/tmux-plugins/tpm"

info " > Installing tpm"
if ! [ -d "$tpm_path" ]; then
  git clone $tpm_url "$tpm_path"
  success "tpm installed"
else
  success "skipped, tpm was installed"
fi
