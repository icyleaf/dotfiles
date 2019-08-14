#!/usr/bin/env bash
#
# Ruby 依赖文件

source functions/_bash

info " > Installing ruby gems"
for gem in "irbtools" \
  "awesome_print" \
  "mush" \
  "ruby-debug-ide" \
  "rubocop" \
  "solargraph" \
  "ripper-tags" \
  "debase"; do

  no_installed=$(gem info $gem | grep $gem)
  if [ -z "$no_installed" ]
  then
    gem install "${gem}"
  fi
done
success "ruby"
