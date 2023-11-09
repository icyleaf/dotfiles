ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
source "${ZINIT_HOME}/zinit.zsh"

# Load local config
[[ ! -f ~/.dotfiles/zsh/local.zsh ]] || source ~/.dotfiles/zsh/local.zsh

# Themes

## powerlevel10k
# zinit ice depth=1;
# zinit light romkatv/powerlevel10k
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi
# [[ ! -f ~/.dotfiles/zsh/themes/p10k.zsh ]] || source ~/.dotfiles/zsh/themes/p10k.zsh

## Spaceship
zinit light spaceship-prompt/spaceship-prompt
[[ ! -f ~/.dotfiles/zsh/themes/spaceship.zsh ]] || source ~/.dotfiles/zsh/themes/spaceship.zsh

# Plugins
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light djui/alias-tips
zinit light mollifier/anyframe

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
  #   OMZP::colored-man-pages \
  # as"completion" \
  #   OMZP::docker/_docker

# bindkey '^xb' anyframe-widget-cdr
# autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
# add-zsh-hook chpwd chpwd_recent_dirs

# bindkey '^xr' anyframe-widget-execute-history
# bindkey '^x^b' anyframe-widget-checkout-git-branch

# oh-my-zsh
zinit snippet OMZL::completion.zsh
zinit snippet OMZL::directories.zsh
# zinit snippet OMZL::git.zsh

# zinit ice svn
# zinit snippet OMZP::macos

## plugins
## core
if (( $+commands[zoxide] )); then
  zinit snippet OMZP::zoxide
fi

if (( $+commands[fzf] )); then
  zinit snippet OMZP::fzf
fi
zinit snippet OMZP::sudo
zinit snippet OMZP::rsync
zinit snippet OMZP::git
zinit snippet OMZP::tig
zinit snippet OMZP::git-flow-avh
# zinit snippet OMZP::mosh

## development
if (( $+commands[tmux] )); then
  zinit ice lucid wait="0" atinit"
    ZSH_TMUX_FIXTERM=false;
    if [[ "$TERM" = "alacritty" ]]; then
      ZSH_TMUX_AUTOSTART=true;
      ZSH_TMUX_AUTOCONNECT=true;
    fi;
  "
  zinit snippet OMZP::tmux
  zinit snippet OMZP::tmuxinator
fi

if (( $+commands[nomad] )); then
  zinit ice as"completion"
  zinit snippet OMZP::nomad/_nomad
fi

# ruby
if (( $+commands[asdf] )); then
  zinit snippet OMZP::asdf
fi

if (( $+commands[ruby] )); then
  zinit snippet OMZP::ruby
  zinit snippet OMZP::gem
  zinit snippet OMZP::bundler
fi

if (( $+commands[rake] )); then
  zinit snippet OMZP::rake
fi

if (( $+commands[rails] )); then
  zinit snippet OMZP::rails
fi

# apple development
if (( $+commands[xcodebuild] )); then
  zinit snippet OMZP::xcode
fi

## containerd
if (( $+commands[kubectl] )); then
  zinit snippet OMZP::kubectl
fi

if (( $+commands[docker] )); then
  zinit ice as"completion"
  zinit snippet OMZP::docker/completions/_docker
fi

if (( $+commands[docker-compose] )); then
  zinit snippet OMZP::docker-compose
  zinit ice as"completion"
  zinit snippet OMZP::docker-compose/_docker-compose
fi

if (( $+commands[terraform] )); then
  zinit ice ver"feat/add-arm64-macos"
  zinit light icyleaf/zsh-terraform
fi

if (( $+commands[atuin] )); then
  source <(atuin init zsh --disable-up-arrow --disable-ctrl-r)
fi

## local plugins
LOCAL_PLUGINS="${HOME:-~}/.dotfiles/zsh/plugins/"
zinit ice lucid nocompile
zinit snippet "${LOCAL_PLUGINS}/talosctl.plugin.zsh"
zinit ice lucid nocompile
zinit snippet "${LOCAL_PLUGINS}/limactl.plugin.zsh"
zinit ice lucid nocompile
zinit snippet "${LOCAL_PLUGINS}/gpg.plugin.zsh"
zinit ice lucid nocompile
zinit snippet "${LOCAL_PLUGINS}/exa.plugin.zsh"
zinit ice lucid nocompile
zinit snippet "${LOCAL_PLUGINS}/homebrew.plugin.zsh"
zinit ice lucid nocompile
zinit snippet "${LOCAL_PLUGINS}/gpg.plugin.zsh"

# completion generation
# autoload -Uz compinit
# compinit

# alias
source $HOME/.dotfiles/zsh/alias.zsh

# Compilation flags
export ARCHFLAGS="-arch $(uname -m)"

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
export EDITOR=hx

# gpg
export GPG_TTY=$(tty)

# Android SDK 路径（Android Studio）
export REPO_OS_OVERRIDE=macosx
export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
export PATH="${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${ANDROID_SDK_ROOT}/tools/bin:$PATH"
