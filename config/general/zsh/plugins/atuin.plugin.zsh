if (( ! $+commands[atuin] )); then
  return
fi

eval "$(atuin init zsh --disable-up-arrow)"
