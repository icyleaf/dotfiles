if (( ! $+commands[mise] )); then
  return
fi

eval "$(/usr/local/bin/mise activate zsh)"
