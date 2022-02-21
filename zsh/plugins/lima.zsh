if test "$(uname)" = "Darwin"; then
  if test $(which lima); then
    ZSH_COMPLETION_PATH="/usr/local/share/zsh/site-functions"
    LIMACTL_COMPLETION_FILE="${ZSH_COMPLETION_PATH}/_limactl"
    NERDCTL_COMPLETION_FILE="${ZSH_COMPLETION_PATH}/_nerdctl"

    # lima completion
    if ! [ -f "$LIMACTL_COMPLETION_FILE" ]; then
      limactl completion zsh > $LIMACTL_COMPLETION_FILE
    fi

    if ! [ -z "$(limactl list &> /dev/null | grep default | grep Running)" ]; then
      nerdctl.lima completion zsh > $NERDCTL_COMPLETION_FILE
    fi

    unset ZSH_COMPLETION_PATH
    unset LIMACTL_COMPLETION_FILE
    unset NERDCTL_COMPLETION_FILE
  fi
fi
