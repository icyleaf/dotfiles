#!/usr/bin/env bash
#
# Ruby 依赖文件
source functions/_lib.sh

ruby_version=3.0.3

info "Detect asdf"
if ! test $(which asdf); then
  fail "abort, asdf not installed"
else
  success "asdf existed"
fi

info "Install asdf ruby plugin"
if [ -z "$(asdf plugin list | grep ruby)" ]; then
  asdf plugin add ruby
  success "asdf-ruby"
else
  success "asdf-ruby"
fi

info "Install Ruby $ruby_version"
if [ -z "$(ruby -v | grep $ruby_version)" ]; then
  asdf install ruby $ruby_version
  asdf global ruby $ruby_version
  asdf local ruby $ruby_version
else
  asdf global ruby $ruby_version
  asdf local ruby $ruby_version
fi
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
