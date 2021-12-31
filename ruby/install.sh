#!/usr/bin/env bash
#
# Ruby 依赖文件
source functions/_lib.sh

# rvm_db_path="${HOME:-~}/.rvm/user/db"
# rvm_ruby_url="ruby_url=https://cache.ruby-china.com/pub/ruby"
# ruby_version=2.7.2

# info "Installing rvm"
# if test ! $(which rvm); then
#   gpg --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
#   curl -sSL https://get.rvm.io | bash -s stable
#   source ~/.zshrc
#   success "rvm"
# else
#   success "skipped, rvm was installed `pwd`"
# fi

# info "Replace RVM source to ruby-china"
# if [ -f "$rvm_db_path" ]; then
#   if ! grep -q "$rvm_ruby_url" $rvm_db_path; then
#     echo "ruby_url=$rvm_ruby_url" > ~/.rvm/user/db
#     success 'rvm source replaced'
#   fi
# else
#   success "skipped, rvm was replaced `pwd`"
# fi

ruby_version=3.0.0
asdf_path="${HOME:-~}/.asdf"

info "Installing asdf"
if test ! $(which asdf); then
  git clone https://github.com/asdf-vm/asdf.git $asdf_path
  success "asdf"
else
  success "skipped, asdf was installed `pwd`"
fi

info "Install Ruby $ruby_version"
if [ -z "$(ruby -v | grep $ruby_version)" ]; then
  asdf plugin add ruby
  asdf install ruby $ruby_version
  asdf global ruby $ruby_version
else
  asdf global ruby $ruby_version
fi
success "Ruby $ruby_version"

info "Installing ruby gems"
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
