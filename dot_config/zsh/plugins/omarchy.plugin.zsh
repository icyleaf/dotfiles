if test ! "$(uname -s)" = "Linux"; then
  return
fi

export OMARCHY_PATH="$HOME/.local/share/omarchy"

export PATH="$OMARCHY_PATH/bin:$HOME/.local/bin:$PATH"
