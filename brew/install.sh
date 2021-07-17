#!/usr/bin/env bash
#
# homebrew

source functions/_bash
ensure_macos

brew_path=`pwd`

# user "Enable replace brew git source:\n\n\
#          -> https://mirrors.tuna.tsinghua.edu.cn\n\n\
#        what do you want to do?\n\
#        [y]es, [n]o: "
# read -n 1 action
# case "$action" in
#   y|Y )
#     export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
#     export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
#     ;;
#   * )
#     ;;
# esac

info " > Installing homebrew"
if test ! $(which brew); then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # 安装 tap
  brew tap homebrew/cask-fonts
  brew tap homebrew/cask-drivers
  brew tap kopia/kopia

  # 替换为国内源
  git -C "$(brew --repo)" remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git
  BREW_TAPS="$(brew tap)"
  for tap in core services cask{,-fonts,-drivers}; do
    if echo "$BREW_TAPS" | grep -qE "^homebrew/${tap}\$"; then
      git -C "$(brew --repo homebrew/${tap})" remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-${tap}.git
      git -C "$(brew --repo homebrew/${tap})" config homebrew.forceautoupdate true
    fi
  done

  cd $brew_path
  brew update-reset

  success "homebrew"
else
  success "skipped, homebrew was installed `pwd`"
fi

# 安装 Brewfile 里面的内容
info "Installing brew bundle"
cd "${brew_path}/brew"
brew bundle -v
success "brew bundle"
