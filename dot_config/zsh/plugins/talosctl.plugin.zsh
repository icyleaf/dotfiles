if (( ! $+commands[talosctl] )); then
  return
fi

alias t=talosctl

# Low speed version
source <(talosctl completion zsh)
compdef _talosctl talosctl
compdef _talosctl t

# New version
# if [[ ! -f "$ZSH_CACHE_DIR/completions/_talosctl" ]]; then
#   typeset -g -A _comps
#   autoload -Uz _talosctl
#   _comps[talosctl]=_talosctl
# fi
# talosctl completion zsh 2> /dev/null >| "$ZSH_CACHE_DIR/completions/_talosctl" &|


# Legacy
# if (( $+commands[talosctl] )); then
#   mkdir -p $ZSH_CACHE_DIR/completions >/dev/null
#   TALOSCTL_COMPLETION_FILE="${ZSH_CACHE_DIR}/completions/_talosctl"

#   # If the completion file does not exist, generate it and then source it
#   # Otherwise, source it and regenerate in the background
#   if [[ ! -f "$TALOSCTL_COMPLETION_FILE" ]]; then
#     talosctl completion zsh | tee "$TALOSCTL_COMPLETION_FILE" >/dev/null
#     source "$TALOSCTL_COMPLETION_FILE"
#   else
#     source "$TALOSCTL_COMPLETION_FILE"
#     talosctl completion zsh | tee "$TALOSCTL_COMPLETION_FILE" >/dev/null &|
#   fi

#   # This command is used a LOT both below and in daily life
#   alias t=talosctl

#   unset TALOSCTL_COMPLETION_FILE
# fi
