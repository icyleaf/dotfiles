#!/usr/bin/env bash
#
# gungpg

source functions/_bash

root_path=`pwd`
target_path="${HOME:-~}/.gnupg"

info " > Link gnupg"
if ! [ -d "${target_path}" ]; then
  mkdir $target_path
fi

link_file "${root_path}/gnupg/gpg-agent.config" "$target_path/gpg-agent.config"
