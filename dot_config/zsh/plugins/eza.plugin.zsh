# Inspired from https://github.com/MohamedElashri/exa-zsh/blob/main/exa-zsh.plugin.zsh
if (( ! $+commands[eza] )); then
  return
fi

# general use aliases
alias ls='eza --icons=always $@' # just replace ls by exa and allow all other exa arguments
alias l='ls -lbF' #   list, size, type
alias ll='ls -la' # long, all
alias llm='ll --sort=modified' # list, long, sort by modification date
alias la='ls -lbhHigUmuSa' # all list
alias lx='ls -lbhHigUmuSa@' # all list and extended
alias tree='eza --tree -L1' # tree view
alias lS='eza -1' # one column by just names
