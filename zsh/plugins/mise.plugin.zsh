if (( ! $+commands[mise] )); then
  return
fi

if [[ -x /opt/homebrew/bin/mise ]]; then
  MISE_LOCATION="/opt/homebrew/bin/mise"
elif [[ -x /usr/local/bin/mise ]]; then
  MISE_LOCATION="/usr/local/bin/mise"
else
  return
fi

eval "$("$MISE_LOCATION" activate zsh)"
unset MISE_LOCATION
