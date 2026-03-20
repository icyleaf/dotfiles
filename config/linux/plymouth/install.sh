#!/usr/bin/env bash
#
# 安装 plymouth 主题

source functions/_lib.sh

ROOTPATH=$(readlink -f "${DIRPATH}/../../..")

# get hostname
hostname=$(hostname)

src_theme_path="${ROOTPATH}/linux/local/share/plymouth/themes/${hostname}"
dest_theme_path="/usr/share/plymouth/themes/${hostname}"

echo "Installing plymouth theme ${hostname}...${src_theme_path}"

if [[ -d "$src_theme_path" && $(plymouth-set-default-theme) != "$hostname" ]]; then
  info "Installing plymouth theme ... ${hostname}"
  sudo cp -r "$src_theme_path" "$dest_theme_path"

  info "Setting plymouth theme ${hostname} as default..."
  sudo plymouth-set-default-theme $hostname

  success "plymouth theme ${hostname} installed and set as default successfully."
fi
