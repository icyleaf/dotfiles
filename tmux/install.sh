tpm_path="$HOME/.tmux/plugins/tpm"
tpm_url="https://github.com/tmux-plugins/tpm"

if [ -z "$tpm_path" ]
then
    info " > Installing tpm"
    git clone $tpm_url
    success "tpm"
  fi
fi
