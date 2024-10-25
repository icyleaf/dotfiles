if (( ! $+commands[mise] )); then
  return
fi

# installed from homebrew
possible_paths=("/usr/local/bin/mise" "/usr/bin/mise" "$HOME/.local/bin/mise")
mise_path="${possible_paths[-1]}"
for path in "${possible_paths[@]}"; do
  if [ -f "$path" ]; then
    mise_path="$path"
    break
  fi
done

if [ -f "$mise_path" ]; then
  eval "$($mise_path activate zsh)"
else
  echo "Not found mise"
fi
