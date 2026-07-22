#!/usr/bin/env bash
#
# 安装并配置 Ghostty

source functions/_lib.sh

dest_path="${HOME:-~}/.config/ghostty"
mkdir -p "$dest_path" 2>/dev/null

# 1. 确保子模块初始化并拉取最新状态
if [ ! -f "${DIRPATH}/warp/gconfig" ]; then
  info "Initializing ghostty-warp submodule..."
  git submodule update --init --recursive "${DIRPATH}/warp"
fi

# 2. 链接子模块中的基础资产文件夹和文件
if [ -d "${DIRPATH}/warp" ]; then
  for dir in presets themes fonts platform keybinds; do
    if [ -d "${DIRPATH}/warp/${dir}" ]; then
      mkdir -p "${dest_path}/${dir}"
      for file in $(find "${DIRPATH}/warp/${dir}" -type f); do
        rel_file="${file#${DIRPATH}/warp/}"
        link_file "$file" "${dest_path}/${rel_file}"
      done
    fi
  done
  link_file "${DIRPATH}/warp/config" "${dest_path}/config"
  link_file "${DIRPATH}/warp/gconfig" "${dest_path}/gconfig"
fi

# 3. 链接本地覆盖资产文件（如果有）
for dir in presets themes fonts platform keybinds; do
  if [ -d "${DIRPATH}/${dir}" ]; then
    mkdir -p "${dest_path}/${dir}"
    for file in $(find "${DIRPATH}/${dir}" -type f); do
      rel_file="${file#${DIRPATH}/}"
      link_file "$file" "${dest_path}/${rel_file}"
    done
  fi
done

# 如果本地有自定义 config，则覆盖链接
if [ -f "${DIRPATH}/config" ]; then
  link_file "${DIRPATH}/config" "${dest_path}/config"
fi

# 4. 链接 gconfig 到全局 ~/.local/bin，以方便调用
ensure_local_bin
link_file "${dest_path}/gconfig" "${LOCAL_BIN_DIR}/gconfig"
