#!/usr/bin/env bash
#
# Ruby 依赖文件
source functions/_lib.sh

ruby_version=3.3.5

if ! test $(which mise); then
  fail "abort, mise not installed"
fi

if [ -z "$(ruby -v | grep $ruby_version)" ]; then
  info "Install Ruby $ruby_version"
  mise install ruby $ruby_version
fi
mise global ruby $ruby_version &> /dev/null

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
