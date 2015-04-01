#!/usr/bin/env bash
#
# bootstrap installs things.

source functions/_bash

DOTFILES_ROOT="`pwd`"

if ! [ -z "$DOTFILES_PATH" ]
then
  fail "Dotfile already install in ${DOTFILES_PATH}"
fi

setup_gitconfig () {
  gitconfig_file='git/dotfiles/gitconfig'
  gitconfig_template='git/template/gitconfig'

  if ! [ -f $gitconfig_file ]
  then
    info 'setup gitconfig'

    git_credential='cache'
    if [ "$(uname -s)" == "Darwin" ]
    then
      git_credential='osxkeychain'
    fi

    user ' - What is your github author name?'
    read -e git_authorname
    user ' - What is your github author email?'
    read -e git_authoremail

    sed -e "s/AUTHORNAME/$git_authorname/g" -e "s/AUTHOREMAIL/$git_authoremail/g" -e "s/GIT_CREDENTIAL_HELPER/$git_credential/g" $gitconfig_template > $gitconfig_file
  fi

  success 'gitconfig updated'
}

link_files () {
  if [ "$3" == "true" ]
  then
    sudo ln -i $1 $2
  else 
    ln -s $1 $2
  fi

  success "linked $1 to $2"
}

link_dotfiles () {
  info 'installing dotfiles'

  overwrite_all=false
  backup_all=false
  skip_all=false

  for source in `find $DOTFILES_ROOT -d 3 -regex ".*/dotfiles/.*" ! -iname ".DS_Store"`
  do
    dest="$HOME/.`basename \"${source}\"`"
    linking_file $source $dest
  done
}

link_system_files () {
  overwrite_all=false
  backup_all=false
  skip_all=false

  system_path="${DOTFILES_ROOT}/system"
  for source in `find $system_path -type f ! -iname ".DS_Store"`
  do
    dest=${source//$system_path/''}
    linking_file $source $dest true
  done
}

# linking_file
linking_file() {
  source=$1
  dest=$2
  sudo=$3

  echo "$(ls -l ${dest} | grep \"${source}\")"
  if ([ -L $dest ] || [ -d $dest ]) && [ -n "$(ls -l ${dest} | grep \"${source}\")" ]
  then
    success "$source already linked to $dest"
    return
  else
    echo $source
    echo "$dest not exists"
  fi

  if [ -f $dest ] || [ -d $dest ] || [ -L $dest ]
  then
    overwrite=false
    backup=false
    skip=false

    if [ "$overwrite_all" == "false" ] && [ "$backup_all" == "false" ] && [ "$skip_all" == "false" ]
    then
      user "File already exists: $dest, choose: [s]kip, [S]kip all, [o]verwrite, [O]verwrite all, [b]ackup, [B]ackup all?"
      read -n 1 action

      case "$action" in
        o )
          overwrite=true;;
        O )
          overwrite_all=true;;
        b )
          backup=true;;
        B )
          backup_all=true;;
        s )
          skip=true;;
        S )
          skip_all=true;;
        * )
          ;;
      esac
    fi

    if [ "$overwrite" == "true" ] || [ "$overwrite_all" == "true" ]
    then
      if [ "$sudo" == "true" ]
      then
        sudo rm -rf $dest
      else
        rm -rf $dest
      fi
      success "removed $dest"
    fi

    if [ "$backup" == "true" ] || [ "$backup_all" == "true" ]
    then
      if [ "$sudo" == "true" ]
      then
        sudo mv $dest $dest\.backup
      else
        mv $dest $dest\.backup
      fi
      success "moved $dest to $dest.backup"
    fi

    if [ "$skip" == "false" ] && [ "$skip_all" == "false" ]
    then
      link_files $source $dest $sudo
    else
      success "skipped $source"
    fi

  else
    link_files $source $dest $sudo
  fi
}


install_apps () {
  if test ! $(which brew)
  then
    info 'installing homebrew'
    sh -c "brew/init.sh"
    success 'homebrew installed'
  fi

  for installer in `find $DOTFILES_ROOT -d 2 -name "install.sh"`
  do
    info $installer
    sh -c "${installer}"
  done
}

main () {
  if [ "$(uname -s)" == "Darwin" ]
  then
    session 'Setup git config'
    setup_gitconfig

    session 'Linking dotfiles'
    link_dotfiles

    session 'Linking system files'
    link_system_files
    exit 0

    session 'Install Apps'
    install_apps

    echo ''
    echo '  All installed!'
    echo ''
  else
    fail "Your OS is not Mac OS X"
  fi
}

main