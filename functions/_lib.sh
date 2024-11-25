# Helper

set -euo pipefail
test "${DEBUG:-}" && set -x

# From https://stackoverflow.com/a/3572105
read_path () (
  [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
)

DIRPATH=$(read_path $(dirname "$0"))
ROOTPATH=$(readlink -f "${DIRPATH}/..")

overwrite_all=false
backup_all=false
skip_all=false

os_name () {
  case "$(uname -s)" in
    Darwin)
      echo "macos"
      ;;
    Linux)
      echo "linux"
      ;;
    CYGWIN*|MINGW*|MSYS*)
      echo "windows"
      ;;
    *)
      echo "unknown"
      ;;
  esac
}

ensure_macos () {
  if test ! "$(os_name)" = "macos"; then
    exit 0
  fi
}

ensure_linux () {
  if test ! "$(os_name)" = "linux"; then
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
          o)
            overwrite=true;;
          O)
            overwrite_all=true;;
          b)
            backup=true;;
          B)
            backup_all=true;;
          s)
            skip=true;;
          S)
            skip_all=true;;
          *)
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
    success "linked $2 from $1"
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

ask_for_sudo() {
  # Ask for the administrator password upfront
  sudo -v

  # Update existing `sudo` time stamp until this script has finished
  # https://gist.github.com/cowboy/3118588
  while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
  done &> /dev/null &
}

if [[ -t 1 ]]
then
  tty_escape() { printf "\033[%sm" "$1"; }
else
  tty_escape() { :; }
fi
tty_mkbold() { tty_escape "1;$1"; }
tty_underline="$(tty_escape "4;39")"
tty_green="$(tty_mkbold 32)"
tty_blue="$(tty_mkbold 34)"
tty_red="$(tty_mkbold 31)"
tty_cyan="$(tty_mkbold 36)"
ttt_yellow="$(tty_mkbold 33)"
tty_bold="$(tty_mkbold 39)"
tty_reset="$(tty_escape 0)"

shell_join() {
  local arg
  printf "%s" "$1"
  shift
  for arg in "$@"
  do
    printf " "
    printf "%s" "${arg// /\ }"
  done
}

title() {
  printf "${tty_blue}==>${tty_bold} %s${tty_reset}\n" "$(shell_join "$@")"
}

info () {
  printf "[ ${tty_blue}..${tty_reset} ] $1\n"
}

user () {
  printf "[ ${tty_cyan}??${tty_reset} ] $1\n"
}

success () {
  printf "[ ${tty_green}OK${tty_reset} ] $1\n"
}

warn () {
  printf "[${ttt_yellow}WARN${tty_reset}] $1\n"
}

fail () {
  printf "[${tty_red}FAIL${tty_reset}] $1\n"
  echo ''
  exit
}

tips () {
  printf "\r  \033[0;36m$1\033[0m\n"
}
