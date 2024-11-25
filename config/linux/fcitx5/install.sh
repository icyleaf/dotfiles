#!/usr/bin/env bash

source functions/_lib.sh

config_path="${HOME:-~}/.config/fcitx5"
share_path="${HOME:-~}/.local/share/fcitx5"

mkdir -p "$config_path/themes" 2>/dev/null
link_file "${DIRPATH}" "${config_path}"

mkdir -p $share_path 2>/dev/null
# install fcitx5 themes
if ! [ -d "$share_path/themes" ]; then
  git clone https://github.com/catppuccin/fcitx5.git /tmp/fcitx5-themes
  cp -r /tmp/fcitx5-themes/src/* "$share_path/themes"
  rm -rf /tmp/fcitx5-themes
fi

# install rime chinese input
rime_path="$share_path/rime"
if ! [ -d "$rime_path" ]; then
  git clone https://github.com/gaboolic/rime-frost.git "$rime_path"
fi
