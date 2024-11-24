if (( ! $+commands[limactl] )); then
  return
fi

# source <(limactl completion zsh)
# compdef _limactl limactl

if (( $+commands[limactl] )); then
  mkdir -p $ZSH_CACHE_DIR/completions >/dev/null

  LIMACTL_COMPLETION_FILE="${ZSH_CACHE_DIR}/completions/_limactl"
  NERDCTL_COMPLETION_FILE="${ZSH_COMPLETION_PATH}/completions/_nerdctl"

  # If the completion file does not exist, generate it and then source it
  # Otherwise, source it and regenerate in the background
  if [[ ! -f "$TALOSCTL_COMPLETION_FILE" ]]; then
    limactl completion zsh | tee "$LIMACTL_COMPLETION_FILE" >/dev/null
    # source "$LIMACTL_COMPLETION_FILE"
  else
    # source "$LIMACTL_COMPLETION_FILE"
    limactl completion zsh | tee "$LIMACTL_COMPLETION_FILE" >/dev/null &|
  fi

  # if [[ ! -f "$NERDCTL_COMPLETION_FILE" ]]; then
  #   nerdctl.lima completion zsh | tee "$NERDCTL_COMPLETION_FILE" >/dev/null
  #   # source "$NERDCTL_COMPLETION_FILE"
  # else
  #   # source "$NERDCTL_COMPLETION_FILE"
  #   nerdctl.lima completion zsh | tee "$NERDCTL_COMPLETION_FILE" >/dev/null &|
  # fi

  unset LIMACTL_COMPLETION_FILE
  unset NERDCTL_COMPLETION_FILE
fi
