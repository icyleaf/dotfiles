#!/usr/bin/env bash
#
# 复制 Karbiner-Elements 的配置文件

source functions/_bash

src="config/karbiner/karbiner.json"
desc="~/.$src"

echo " > Linking ${desc}"
link_file "$src" "$desc"
