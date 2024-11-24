#!/usr/bin/env bash
#
# 链接 keyd 的配置文件

source functions/_lib.sh

dest_path="${HOME:-~}/.config/keyd"

mkdir -p $dest_path 2> /dev/null
for config in $(ls $DIRPATH/system/*.conf); do
  file=$(basename $config)
  link_file "$config" "/etc/keyd/$file"
done

for config in $(ls $DIRPATH/*.conf); do
  file=$(basename $config)
  link_file "$config" "${dest_path}/$file"
done

