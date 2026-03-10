#!/usr/bin/env bash
#
# Tmux
source functions/_lib.sh

source_path="tmux.conf"

tpm_url="https://github.com/tmux-plugins/tpm"

# 检测 tmux 版本，决定配置文件位置
# tmux 3.2+ 支持 XDG Base Directory 规范 (~/.config/tmux/tmux.conf)
# 旧版本只支持 ~/.tmux.conf
get_tmux_version() {
  tmux -V 2>/dev/null | sed -E 's/.*[^0-9]([0-9]+\.[0-9]+).*/\1/'
}

version_gte() {
  printf '%s\n%s\n' "$1" "$2" | sort -V -C 2>/dev/null
}

TMUX_VERSION=$(get_tmux_version)

if version_gte "$TMUX_VERSION" "3.2"; then
  dest_path="${HOME:-~}/.config/tmux/"
  tpm_path="${dest_path}plugins/tpm"
  mkdir -p "$dest_path/plugins"
  info "Detected tmux $TMUX_VERSION (>= 3.2), using XDG config: ~/.config/tmux/"
else
  dest_path="${HOME:-~}/.tmux/"
  tpm_path="${dest_path}plugins/tpm"
  mkdir -p "$dest_path/plugins"
  # 旧版本需要创建 ~/.tmux.conf 软链接
  link_file "${DIRPATH}/${source_path}" "${HOME:-~}/.tmux.conf"
  info "Detected tmux $TMUX_VERSION (< 3.2), using legacy config: ~/.tmux.conf"
fi

link_file "${DIRPATH}/${source_path}" "$dest_path/$source_path"

info "Installing tpm"
if ! [ -d "$tpm_path" ]; then
  git clone $tpm_url "$tpm_path"
  success "tpm installed"
else
  success "skipped, tpm was installed"
fi
