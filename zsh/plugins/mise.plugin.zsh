if (( ! $+commands[mise] )); then
  return
fi

# installed from homebrew
mise_possible_paths=("/usr/local/bin/mise" "/usr/bin/mise" "$HOME/.local/bin/mise")
mise_path="${mise_possible_paths[-1]}"
for p in "${mise_possible_paths[@]}"; do
  if [ -f "$p" ]; then
    mise_path="$p"
    break
  fi
done

if [ -f "$mise_path" ]; then
  eval "$($mise_path activate zsh)"
else
  echo "Not found mise"
fi
