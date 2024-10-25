if (( ! $+commands[mise] )); then
  return
fi

# installed from homebrew
mise_path="/usr/local/bin/mise"
if ! [ -f "$mise_path" ]; then
  mise_path=$(~/.local/bin/mise)
fi

if [ -f "$mise_path" ]; then
  eval "$($mise_path activate zsh)"
else
  echo "Not found mise"
fi
