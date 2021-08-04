#!/usr/bin/env bash
#
# gungpg

source functions/_lib.sh

gnupg_name=gpg-agent.conf
gnupg_dst="${HOME:-~}/.gnupg"

if ! [ -d "$gnupg_dst" ]; then
  mkdir $gnupg_dst
  chmod 700 $gnupg_dst
fi

link_file "${DIRPATH}/${gnupg_name}" "$gnupg_dst/${gnupg_name}"
