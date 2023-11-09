#!/usr/bin/env bash
#
# homebrew

source functions/_lib.sh

HOMEBREW_SOURCE=https://mirrors.tuna.tsinghua.edu.cn

replace_brew_sources=false
brew_action=

replace_brew_sources () {
  user "Enable replace brew git source:\n\n\
          -> ${HOMEBREW_SOURCE}\n\n\
        what do you want to do?\n\
        [y]es, [n]o: "
  read -n 1 brew_action
  case "$brew_action" in
    y|Y )
      replace_brew_sources=true
      export HOMEBREW_BREW_GIT_REMOTE="${HOMEBREW_SOURCE}/git/homebrew/brew.git"
      export HOMEBREW_CORE_GIT_REMOTE="${HOMEBREW_SOURCE}/git/homebrew/homebrew-core.git"
      ;;
    * )
      ;;
  esac
}


info "Installing homebrew"
if test ! $(which brew); then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # 替换为国内源
  if [ "$replace_brew_sources" == "true" ]; then
    git -C "$(brew --repo)" remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git
    BREW_TAPS="$(brew tap)"
    for tap in core services cask{,-fonts,-drivers}; do
      if echo "$BREW_TAPS" | grep -qE "^homebrew/${tap}\$"; then
        git -C "$(brew --repo homebrew/${tap})" remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-${tap}.git
        git -C "$(brew --repo homebrew/${tap})" config homebrew.forceautoupdate true
      fi
    done

    cd $ROOTPATH
    brew update-reset
  fi

  success "homebrew installed"
else
  success "Skipped, homebrew was installed"
fi

# 安装 Brewfile 里面的内容
info "Installing brew bundle"
cd "${DIRPATH}"
brew bundle -v
success "brew bundle installed"
