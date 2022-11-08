if ! (( $+commands[hx] )); then
  print "helix.plugin.zsh: hx not found on path. Please install helix before using this plugin." >&2
  return 1
fi
