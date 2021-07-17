#!/usr/bin/env bash
#
# vscode

source functions/_lib.sh
ensure_macos

DOTFILES_ROOT="`pwd`"

info "Setup VSCode"
if test ! $(which code); then
  info "Linking code command"
  code_path="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"

  link_file $code_path /usr/local/bin/code
  success 'gitconfig'
fi

settings_sync_file="$HOME/Library/Application Support/Code/User/syncLocalSettings.json"

if [ -z "$(code --list-extensions| grep Shan.code-settings-sync)" ]; then
  info "Install Settings Sync"
  code --install-extension Shan.code-settings-sync
fi

if ! [ -f "vscode/syncLocalSettings.json" ]; then
  user ' - What is your github access token?'
  read -e github_access_token

  sed -e "s/GITHUB_ACCESS_TOKEN/$github_access_token/g" vscode/syncLocalSettings.json.example > vscode/syncLocalSettings.json
fi

link_file "${DOTFILES_ROOT}/vscode/syncLocalSettings.json" "$settings_sync_file"
success "Setup VSCode"
