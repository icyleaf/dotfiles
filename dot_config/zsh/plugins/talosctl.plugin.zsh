if (( ! $+commands[talosctl] )); then
  return
fi

alias t=talosctl

# Low speed version
source <(talosctl completion zsh)
compdef _talosctl talosctl
compdef _talosctl t

