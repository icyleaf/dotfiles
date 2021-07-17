#!/usr/bin/env bash
#
# Ruby 依赖文件
source functions/_lib.sh

local rvm_db_path="$HOME/.rvm/user/db"
local rvm_ruby_url="ruby_url=https://cache.ruby-china.com/pub/ruby"
local ruby_version=2.7.2

info " > Installing rvm"
if test ! $(which rvm); then
  curl -sSL https://get.rvm.io | bash -s stable
  source ~/.bashrc
  source ~/.bash_profile
  success "rvm"
else
  success "skipped, rvm was installed `pwd`"
fi

info " > Replace RVM source to ruby-china"
if [ -f "$rvm_db_path" ]; then
  if ! grep -q "$rvm_ruby_url" $rvm_db_path; then
    echo "ruby_url=$rvm_ruby_url" > ~/.rvm/user/db
    success 'rvm source replaced'
  fi
else
  success "skipped, rvm was replaced `pwd`"
fi

info " > Install Ruby $ruby_version"
rvm install $ruby_version --disable-binary
rvm use $ruby_version --default
success "Ruby $ruby_version"

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
success "ruby gems"
