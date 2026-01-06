ensure_macos () {
  if test ! "$(uname)" = "Darwin"; then
    exit 0
  fi
}

is_silicon_macos () {
  if [[ "$(uname -m)" == "arm64" ]]; then
    return 0
  else
    return 1
  fi
}

ensure_macos

zinit wait lucid for \
  atclone"touch music spotify _security" atpull"%atclone" 'OMZP::macos'

if is_silicon_macos; then
  export LIBRARY_PATH=$LIBRARY_PATH:/opt/homebrew/lib
  export CPATH=$CPATH:/opt/homebrew/include
fi
