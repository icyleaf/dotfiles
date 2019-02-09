#!/usr/bin/env bash
#
# 复制 Karbiner-Elements 的配置文件

source functions/_bash

karbiner_pwd=`pwd`

src="config/karbiner"
desc="~/$HOME/$src"

echo " > Linking ${desc}"
link_file "${karbiner_pwd}/${src}" "$desc"
