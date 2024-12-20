# Helper

set -euo pipefail
test "${DEBUG:-}" && set -x

# From https://stackoverflow.com/a/3572105
read_path () (
  [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
)

DIRPATH=$(read_path $(dirname "$0"))
ROOTPATH=$(read_path "${DIRPATH}/..")

overwrite_all=false
backup_all=false
skip_all=false

ensure_macos () {
  if test ! "$(uname)" = "Darwin"; then
    exit 0
  fi
}

ensure_linux () {
  if test ! "$(uname)" = "Linux"; then
    exit 0
  fi
}

link_file () {
  local src=$1 dst=$2

  local overwrite= backup= skip=
  local action=

  if [ -f "$dst" -o -d "$dst" -o -L "$dst" ]; then
    if [ "$overwrite_all" == "false" ] && [ "$backup_all" == "false" ] && [ "$skip_all" == "false" ]; then
      local currentSrc="$(readlink $dst)"
      if [ "$currentSrc" == "$src" ]; then
        skip=true;
      else
        user "File already exists: $dst (${src#$ROOTPATH/}), what do you want to do?\n\
        [s]kip, [S]kip all, [o]verwrite, [O]verwrite all, [b]ackup, [B]ackup all?"

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
    fi

    overwrite=${overwrite:-$overwrite_all}
    backup=${backup:-$backup_all}
    skip=${skip:-$skip_all}

    if [ "$overwrite" == "true" ]; then
      rm -rf "$dst"
      success "removed $dst"
    fi

    if [ "$backup" == "true" ]; then
      mv "$dst" "${dst}.backup"
      success "moved $dst to ${dst}.backup"
    fi

    if [ "$skip" == "true" ]; then
      success "skipped $src"
    fi
  fi

  # "false" or empty
  if [ "$skip" != "true" ]; then
    ln -s "$1" "$2"
    success "linked $1 to $2"
  fi
}

remove_dock_icon() {
  local bundle_identifier=$1
  local position=$(defaults read com.apple.dock persistent-apps | grep bundle-identifier | awk "/${bundle_identifier}/  {printf NR}")
  local index=$[${position}-1]

  if [ $index -ge 0 ]
  then
    tips "deleted ${bundle_identifier}"
    /usr/libexec/PlistBuddy -c "Delete persistent-apps:$index" ~/Library/Preferences/com.apple.dock.plist
  fi
}

info () {
  printf "\r  [ \033[00;34m..\033[0m ] $1\n"
}

user () {
  printf "\r  [ \033[0;33m??\033[0m ] $1\n"
}

success () {
  printf "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n"
}

warn () {
  printf "\r\033[2K  [\033[0;36mWARN\033[0m] $1\n"
}

fail () {
  printf "\r\033[2K  [\033[0;31mFAIL\033[0m] $1\n"
  echo ''
  exit
}

tips () {
  printf "\r  \033[0;36m$1\033[0m\n"
}
