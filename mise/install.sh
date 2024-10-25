#!/usr/bin/env bash
#
# mise

source functions/_lib.sh

source_path="config.toml"
dest_path="${HOME:-~}/.config/mise"

link_file "${DIRPATH}/${source_path}" "$dest_path"
