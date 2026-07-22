#!/usr/bin/env bash
#
# 链接 walker 的配置文件

source functions/_lib.sh

dest_path="${HOME:-~}/.config/walker"

mkdir -p $dest_path 2> /dev/null
link_file "${DIRPATH}/config.toml" "${dest_path}/config.toml"
link_file "${DIRPATH}/themes" "${dest_path}/themes"

# Link walker custom scripts to ~/.local/bin
ensure_local_bin
for script in "${DIRPATH}"/bin/walker-*; do
  if [[ -f "$script" ]]; then
    link_file "$script" "${LOCAL_BIN_DIR}/$(basename "$script")"
  fi
done
