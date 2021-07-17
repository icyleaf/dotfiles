#!/usr/bin/env bash
#
# gungpg

source functions/_lib.sh

target_path="${HOME:-~}/.gnupg"

if ! [ -d "${target_path}" ]; then
  mkdir $target_path
  chmod 700 $target_path
fi

link_file "${ROOTPATH}/gnupg/gpg-agent.conf" "$target_path/gpg-agent.conf"
