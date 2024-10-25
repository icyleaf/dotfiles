#!/usr/bin/env bash
#
# Ruby 依赖文件
source functions/_lib.sh

ruby_version=3.3.5

info "Detect mise"
if ! test $(which mise); then
  fail "abort, mise not installed"
else
  success "mise existed"
fi

info "Install Ruby $ruby_version"
if [ -z "$(ruby -v | grep $ruby_version)" ]; then
  mise install ruby $ruby_version
fi
mise global ruby $ruby_version
success "Ruby $ruby_version"

info "Install ruby gems"
for gem in "irbtools" \
  "awesome_print" \
  "mush" \
  "ruby-debug-ide" \
  "rubocop" \
  "solargraph" \
  "ripper-tags" \
  "debase"; do

  if [ -z "$(gem info $gem | grep $gem)" ]; then
    echo "       > ${gem}"
    gem install "${gem}" &> /dev/null
  fi
done
success "ruby gems"
