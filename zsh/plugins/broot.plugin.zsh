if (( $+commands[broot] )); then
  if ! (( $+commands[br] )); then
    # broot --install >/dev/null

    # https://dystroy.org/broot/install-br/
    eval "$(broot --print-shell-function zsh)"
  fi

  ## broot
  # source $HOME/.config/broot/launcher/bash/br
fi
