HOMEBREW_INSTALLED=0

if test "$(uname)" = "Darwin"; then
  if test "$(uname -m)" = "arm64" && [[ -f "/opt/homebrew/bin/brew" ]]; then
    HOMEBREW_INSTALLED=1
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi

  if [[ -f "/usr/local/bin/brew" ]]; then
    HOMEBREW_INSTALLED=1
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

if [[ "$HOMEBREW_INSTALLED" = 1 ]]; then
  zinit snippet OMZP::brew

  # brew alias
  alias b='brew'
  alias bs='brew services'
  alias bsc='brew services cleanup'
  alias bsl='brew services list'
  alias bsr='brew services restart'
  alias bss='brew services start'

  # 关闭 brew 自动更新功能
  export HOMEBREW_NO_AUTO_UPDATE=1
  export HOMEBREW_NO_ANALYTICS=1
  export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1
fi

unset HOMEBREW_INSTALLED
