if (( ! $+commands[openclaw] )); then
  return
fi

autoload -Uz compinit
compinit

# OpenClaw Completion
if [[ -f "$HOME/.openclaw/completions/openclaw.zsh" ]]; then
  source "$HOME/.openclaw/completions/openclaw.zsh"
fi
