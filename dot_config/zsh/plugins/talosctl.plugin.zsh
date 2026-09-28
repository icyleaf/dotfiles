if (( ! $+commands[talosctl] )); then
  return
fi

alias t=talosctl

# zinit defers compinit (wait ice) until after the first prompt, but this
# plugin is sourced synchronously from .zshrc, so ensure compinit has run
# before registering completions.
if ! (( $+functions[compdef] )); then
  autoload -Uz compinit
  compinit
fi

# Low speed version
source <(talosctl completion zsh)
compdef _talosctl talosctl
compdef _talosctl t

