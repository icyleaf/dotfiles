if (( $+commands[broot] )); then
  if ! (( $+commands[br] )); then
    broot --install >/dev/null
  fi

  ## broot
  source $HOME/.config/broot/launcher/bash/br
fi
