#!/usr/bin/env bash
#
# 安装 VSCode 的插件

source functions/_bash

if test ! $(which code); then
  code_path="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"

  echo "› Linking code command"
  ln -s $code_path /usr/local/bin/code
fi

settings_sync_file="~/Library/Application Support/Code/User/syncLocalSettings.json"
if [ ! -f "$settings_sync_file" ]; then
  echo "›  Install Settings Sync"
  code --install-extension Shan.code-settings-sync

  user ' - What is your github access token?'
  read -e github_access_token
  sed -e "s/GITHUB_ACCESS_TOKEN/$github_access_token/g" vscode/syncLocalSettings.json.example > vscode/syncLocalSettings.json
  ln -s vscode/syncLocalSettings.json "$settings_sync_file.ex"
fi