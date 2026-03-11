if (( ! $+commands[openclaw] )); then
  return
fi

autoload -Uz compinit
compinit

# OpenClaw Completion
source "/Users/icyleaf/.openclaw/completions/openclaw.zsh"
