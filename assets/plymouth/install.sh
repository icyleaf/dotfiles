#!/usr/bin/env bash
#
# 安装 plymouth 主题

# get hostname
hostname=$(hostname)

src_theme_path="${DIRPATH}/themes/${hostname}"
theme_name="$hostname"

if [[ ! -d "$src_theme_path" ]]; then
  # Fallback to achron theme if hostname-specific theme is not found
  src_theme_path="${DIRPATH}/themes/achron"
  theme_name="achron"
fi

echo "Installing plymouth theme ${theme_name}...${src_theme_path}"

if [[ -d "$src_theme_path" ]]; then
  echo "Installing plymouth theme ... ${theme_name}"
  sudo mkdir -p "/usr/share/plymouth/themes"
  sudo cp -rf "$src_theme_path" "/usr/share/plymouth/themes/"

  echo "Setting plymouth theme ${theme_name} as default..."
  sudo plymouth-set-default-theme "$theme_name"

  echo "plymouth theme ${theme_name} installed and set as default successfully."
fi
