if (( ! $+commands[mise] )); then
  return
fi

if declare -F mise > /dev/null; then
  return
fi

mise_path=$(which mise)
eval "$($mise_path activate zsh)"
