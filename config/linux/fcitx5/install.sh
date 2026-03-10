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
rime_plum_path="$share_path/rime-plum"
if ! [ -d "$rime_plum_path" ]; then
  git clone --depth 1 https://github.com/rime/plum.git "$rime_plum_path"
fi

# # install recipes from plum
echo "Installing Rime recipes from plum..."
rime_frondend=fcitx5-rime "$rime_plum_path/rime-install ${DIRPATH}/plum-packages.conf"
