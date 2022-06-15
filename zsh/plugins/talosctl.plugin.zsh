if (( $+commands[talosctl] )); then
  TALOSCTL_COMPLETION_FILE="${ZSH_CACHE_DIR}/completions/_talosctl"

  # If the completion file does not exist, generate it and then source it
  # Otherwise, source it and regenerate in the background
  if [[ ! -f "$TALOSCTL_COMPLETION_FILE" ]]; then
    talosctl completion zsh | tee "$TALOSCTL_COMPLETION_FILE" >/dev/null
    source "$TALOSCTL_COMPLETION_FILE"
  else
    source "$TALOSCTL_COMPLETION_FILE"
    talosctl completion zsh | tee "$TALOSCTL_COMPLETION_FILE" >/dev/null &|
  fi

  # This command is used a LOT both below and in daily life
  alias t=talosctl

  unset TALOSCTL_COMPLETION_FILE
fi
