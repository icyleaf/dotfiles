#!/usr/bin/env bash
#
# vscode

source functions/_lib.sh
ensure_macos

info "Setup VSCode"
if test ! $(which code); then
  info "Linking code command"
  code_path="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"

  link_file $code_path /usr/local/bin/code
fi

success "Setup VSCode"
