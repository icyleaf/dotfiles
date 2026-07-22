if test ! "$(uname -s)" = "Linux"; then
  return
fi

export PATH="$HOME/.local/share/omarchy/bin:$HOME/.local/bin:$PATH"
