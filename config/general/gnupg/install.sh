#!/usr/bin/env bash
#
# gungpg

source functions/_lib.sh

gnupg_name=gpg-agent.conf
gnupg_dst="${HOME:-~}/.gnupg"
gnupg_agent_config_path="${gnupg_dst}/${gnupg_name}"

install_pinentry_mac () {
  local pinentry_path=$(command -v pinentry-mac)
  if test ! "$pinentry_path"; then
    if test ! $(which brew); then
      fail "brew was not installed, run brew/install.sh to install first."
    fi

    brew install gnupg pinentry-mac
  fi

  configure_gpg_agent_file "$pinentry_path"
}

install_pinentry_touchid () {
  local pinentry_path=$(command -v pinentry-touchid)
  if test ! "$pinentry_path"; then
    if test ! $(which brew); then
      fail "brew was not installed, run brew/install.sh to install first."
    fi

    brew install gnupg pinentry-mac pinentry-touchid
  fi

  echo "Disabled gpg store passphrase in keychain"
  defaults write org.gpgtools.common DisableKeychain -bool yes

  configure_gpg_agent_file $pinentry_path
}

install_pinentry_tty () {
  configure_gpg_agent_file $(command -v pinentry-tty)
}

install_pinentry_curses () {
  configure_gpg_agent_file $(command -v pinentry-curses)
}

install_wayprompt () {
  local pinentry_path=$(command -v wayprompt)
  if test ! "$wpath"; then
    if test $(which paru); then
      paru -S wayprompt
    elif test $(which yay); then
      yay -S wayprompt
    else
      fail "paru was not installed, ignore"
    fi
  fi

  configure_gpg_agent_file $pinentry_path
}

configure_gpg_agent_file () {
  local pinentry_path=$1

  if ! [ -d "$gnupg_dst" ]; then
    mkdir $gnupg_dst
    chmod 700 $gnupg_dst
  fi

  info "Configuring gpg-agent"
  cat "$DIRPATH/gpg-agent.example.conf" | sed 's|^# pinentry-program|pinentry-program '"$pinentry_path"'|' > "${DIRPATH}/${gnupg_name}"
  link_file "${DIRPATH}/${gnupg_name}" "$gnupg_dst/${gnupg_name}"

  if [ os_name == "macos" ]; then
    echo "Enable gpg store passphrase in keychain"
    defaults write org.gpgtools.common DisableKeychain -bool no
  fi

  gpgconf --kill gpg-agent
  success "Success gpg-agent"
}

configure_macos_pinentry () {
  local path=""
  user "Which pinentry binary do you want to use?\n\
        1 pinentry-mac\n\
        2 pinentry-touchid\n\
        3 back to top menu\n\
        4 skip this step"
  read -n 1 path
  echo ""
  case "$path" in
    1)
      install_pinentry_mac;;
    2)
      install_pinentry_touchid;;
    3)
      choose_pinentry_binary;;
    4)
      ;;
    *)
      warn "Incorrect operation, try again!"
      configure_macos_pinentry
      ;;
  esac
}

configure_linux_pinentry () {
  local path=""
  user "Which pinentry binary do you want to use?\n\
        1 pinentry-tty\n\
        2 pinentry-curses\n\
        3 wayprompt\n\
        4 back to top menu\n\
        5 skip this step"
  read -n 1 path
  echo ""
  case "$path" in
    1)
      install_pinentry_tty;;
    2)
      install_pinentry_curses;;
    3)
      install_wayprompt;;
    4)
      choose_pinentry_binary;;
    5)
      ;;
    *)
      warn "Incorrect operation, try again!"
      configure_linux_pinentry
      ;;
  esac
}

choose_pinentry_binary () {
  local action=
  local overwrite= backup= skip=
  if [ -f "$gnupg_agent_config_path" ]; then
    user "File already exists: $gnupg_agent_config_path, what do you want to do?\n\
    [s]kip, [o]verwrite, [b]ackup?"

    read -n 1 action

    case "$action" in
      o|O )
        overwrite=true;;
      b|B )
        backup=true;;
      s|S )
        skip=true;;
      * )
        ;;
    esac
  fi

  if [ "$backup" == "true" ]; then
    mv "$gnupg_agent_config_path" "${gnupg_agent_config_path}.backup"
    success "moved $gnupg_agent_config_path to ${gnupg_agent_config_path}.backup"
  fi

  if [ "$skip" == "true" ]; then
    success "skipped"
  else
    case $(os_name) in
      macos)
        configure_macos_pinentry;;
      linux)
        configure_linux_pinentry;;
      *)
        warn "Unknown platform, skip"
        ;;
    esac
  fi
}

link_file "${DIRPATH}/gpg.conf" "$gnupg_dst/gpg.conf"
choose_pinentry_binary
