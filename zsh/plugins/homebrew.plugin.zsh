if (( ! $+commands[brew] )); then
  return
fi

zinit snippet OMZP::brew

# brew alias
alias bs='brew services'
alias bsc='brew services cleanup'
alias bsl='brew services list'
alias bsr='brew services restart'
alias bss='brew services start'

# 关闭 brew 自动更新功能
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1
