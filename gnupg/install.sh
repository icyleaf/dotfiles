#!/usr/bin/env bash
#
# gungpg

source functions/_lib.sh

gnupg_name=gpg-agent.conf
gnupg_dst="${HOME:-~}/.gnupg"
gnupg_agent_config_path="${gnupg_dst}/${gnupg_name}"

install_pinetry_mac () {
  if test ! $(which pinentry-mac); then
    if test ! $(which brew); then
      fail "brew was not installed, run brew/install.sh to install first."
    fi

    brew install gnupg pinentry-mac
  fi

  configure_gpg_agent_file $(which pinentry-mac)
}

install_pinetry_touchid () {
  if test ! $(which pinentry-touchid); then
    if test ! $(which brew); then
      fail "brew was not installed, run brew/install.sh to install first."
    fi

    brew install gnupg pinentry-mac pinentry-touchid
  fi

  echo "Disabled gpg store passphrase in keychain"
  defaults write org.gpgtools.common DisableKeychain -bool yes

  configure_gpg_agent_file $(which pinentry-touchid)
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

  echo "Enable gpg store passphrase in keychain"
  defaults write org.gpgtools.common DisableKeychain -bool no

  gpgconf --kill gpg-agent
  success "Success gpg-agent"
}

choose_pinetry_binary () {
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
    local path=""
    user "Which pinetry binary do you want to use?\n\
          1 pinetry-[m]ac\n\
          2 pinetry-[t]ouchid\n\
          3 [s]kip this step"
    read -n 1 path
    echo ""
    case "$path" in
      1|m|M )
        install_pinetry_mac
        ;;
      2|t|T )
        install_pinetry_touchid
        ;;
      3|s|S )
        ;;
      * )
        warn "Do not detch any zsh plugin manager, try again!"
        choose_pinetry_binary
        ;;
    esac
  fi
}

link_file "${DIRPATH}/gpg.conf" "$gnupg_dst/gpg.conf"
choose_pinetry_binary
