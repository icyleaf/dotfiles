#!/usr/bin/env bash
#
# Ruby 依赖文件
source functions/_lib.sh

if ! test $(which mise); then
  fail "abort, mise not installed"
fi

for gem in "irbtools" \
  "awesome_print" \
  "mush" \
  "rubocop" \
  "ripper-tags"; do

  if [ -z "$(gem info $gem | grep $gem)" ]; then
    echo "       > ${gem}"
    gem install "${gem}" &> /dev/null
  fi
done
