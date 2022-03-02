ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
source "${ZINIT_HOME}/zinit.zsh"

# Load local config
[[ ! -f ~/.dotfiles/zsh/local.zsh ]] || source ~/.dotfiles/zsh/local.zsh

# Themes

## powerlevel10k
zinit ice depth=1;
zinit light romkatv/powerlevel10k
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
[[ ! -f ~/.dotfiles/zsh/p10k.zsh ]] || source ~/.dotfiles/zsh/p10k.zsh

## pure
# zinit ice pick"async.zsh" src"pure.zsh"
# zinit light sindresorhus/pure

zinit wait lucid for \
      OMZL::git.zsh \
  atload"unalias grv" \
      OMZP::git

zinit wait lucid for \
  atinit"zicompinit; zicdreplay"  \
      zdharma-continuum/fast-syntax-highlighting \
      OMZP::colored-man-pages \
  as"completion" \
      OMZP::docker/_docker

# Plugins
## broot
source /Users/icyleaf/.config/broot/launcher/bash/br

zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
# zinit light zdharma-continuum/fast-syntax-highlighting
zinit light djui/alias-tips

# oh-my-zsh
zinit snippet OMZL::completion.zsh
zinit snippet OMZL::directories.zsh
# zinit snippet OMZL::git.zsh

# zinit ice svn
# zinit snippet OMZP::macos

## plugins
## core
zinit snippet OMZP::zoxide
zinit snippet OMZP::fzf
zinit snippet OMZP::sudo
zinit snippet OMZP::brew
zinit snippet OMZP::rsync
zinit snippet OMZP::git
zinit snippet OMZP::tig
zinit snippet OMZP::git-flow-avh
# zinit snippet OMZP::mosh

## docker
# zinit ice as"completion"
# zinit snippet OMZP::docker/_docker

# zinit snippet OMZP::docker-compose
# zinit ice as"completion"
# zinit snippet OMZP::docker-compose/_docker-compose

## development
zinit snippet OMZP::tmux
zinit snippet OMZP::tmuxinator

# ruby
zinit snippet OMZP::asdf
zinit snippet OMZP::ruby
zinit snippet OMZP::gem
zinit snippet OMZP::bundler
zinit snippet OMZP::rake
zinit snippet OMZP::rails

# ios
zinit snippet OMZP::xcode

# plugins
# wakatime
# zinit load sobolevn/wakatime-zsh-plugin

# zinit wait as"none" \
#   id-as"local-plugins" nocompile \
#   multisrc"${HOME:-~}/.dotfiles/zsh/plugins/*.zsh" \
#   atpull"zinit creinstall -q ${ZDOTDIR}/completions" \
#   run-atpull \
# for icyleaf/icyleaf

zinit ice as"completion" id-as"local-plugin-lima"
zinit snippet "${HOME:-~}/.dotfiles/zsh/plugins/lima.zsh"

# if test "$(uname)" = "Darwin"; then
#   # lima completion
#   zinit light <(limactl completion zsh)

#   if ! [ -z "$(limactl list &> /dev/null | grep default | grep Running)" ]; then
#     zinit light <(nerdctl.lima completion zsh)
#   fi
# fi

# completion generation
autoload -Uz compinit
compinit

# alias
alias flushdns='sudo killall -HUP mDNSResponder'
alias nns="sudo lsof -i -P"
alias nnc="lsof -Pni4 | grep LISTEN"
alias moss='mosh --server=`which mosh-server`'
alias ox='open *.xcodeproj'
alias ow='open *.xcworkspace'
alias la='ll -a'
alias rake='noglob rake'
alias reload='source ~/.zshrc'
alias zshrc='vim ~/.zshrc'

# brew alias
alias b='brew'
alias bs='brew services'
alias bsc='brew services cleanup'
alias bsl='brew services list'
alias bsr='brew services restart'
alias bss='brew services start'

# Compilation flags
export ARCHFLAGS="-arch x86_64"

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
export EDITOR=vim

# 关闭 brew 自动更新功能
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_ANALYTICS=1

# gpg
export GPG_TTY=$(tty)

# Android SDK 路径（Android Studio）
export REPO_OS_OVERRIDE=macosx
export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
export PATH="${ANDROID_SDK_ROOT}/platform-tools:${ANDROID_SDK_ROOT}/tools/bin:$PATH"
