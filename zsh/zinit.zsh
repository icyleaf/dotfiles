TEMP_ZSH_CACHE_DIR=$ZSH_CACHE_DIR
ZSH_CACHE_DIR=${HOME:-~}/.local/share/zinit
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
zinit snippet OMZP::rsync
zinit snippet OMZP::git
zinit snippet OMZP::tig
zinit snippet OMZP::git-flow-avh
# zinit snippet OMZP::mosh

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

## containerd
zinit snippet OMZP::kubectl

if (( $+commands[docker] )); then
  zinit ice as"completion"
  zinit snippet OMZP::docker/_docker
fi

if (( $+commands[docker-compose] )); then
  zinit snippet OMZP::docker-compose
  zinit ice as"completion"
  zinit snippet OMZP::docker-compose/_docker-compose
fi

zinit ice id-as"local-plugin-homebrew"
zinit snippet "${HOME:-~}/.dotfiles/zsh/plugins/homebrew.zsh"

zinit ice id-as"local-plugin-talosctl"
zinit snippet "${HOME:-~}/.dotfiles/zsh/plugins/talosctl.zsh"

zinit ice id-as"local-plugin-broot"
zinit snippet "${HOME:-~}/.dotfiles/zsh/plugins/broot.zsh"

zinit ice as"completion" id-as"local-plugin-lima"
zinit snippet "${HOME:-~}/.dotfiles/zsh/plugins/lima.zsh"

if (( $+commands[terraform] )); then
  zinit light ptavares/zsh-terraform
fi

## plugins

# wakatime
if (( $+commands[wakatime] )); then
  zinit load sobolevn/wakatime-zsh-plugin
fi

# zinit wait as"none" \
#   id-as"local-plugins" nocompile \
#   multisrc"${HOME:-~}/.dotfiles/zsh/plugins/*.zsh" \
#   atpull"zinit creinstall -q ${ZDOTDIR}/completions" \
#   run-atpull \
# for icyleaf/icyleaf

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

# Compilation flags
export ARCHFLAGS="-arch $(uname -m)"

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
export EDITOR=vim

# gpg
export GPG_TTY=$(tty)

# Android SDK 路径（Android Studio）
export REPO_OS_OVERRIDE=macosx
export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
export PATH="${ANDROID_SDK_ROOT}/platform-tools:${ANDROID_SDK_ROOT}/tools/bin:$PATH"

ZSH_CACHE_DIR=$TEMP_ZSH_CACHE_DIR
unset TEMP_ZSH_CACHE_DIR

source /Users/icyleaf/.config/broot/launcher/bash/br
