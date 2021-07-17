#!/usr/bin/env bash
#
# gungpg

source functions/_lib.sh

gnupg_name=gpg-agent.conf
gnupg_dst="${HOME:-~}/.gnupg"

if ! [ -d "$gnupg_dst" ]; then
  mkdir $target_path
  chmod 700 $target_path
fi

link_file "${DIRPATH}/${gnupg_name}" "$gnupg_dst/${gnupg_name}"
