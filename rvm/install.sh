#!/usr/bin/env bash
#
# rvm

source functions/_bash

rvm_db_path="$HOME/.rvm/user/db"
rvm_ruby_url="ruby_url=https://cache.ruby-china.com/pub/ruby"

info "Replace RVM source to ruby-china"
if [ -z "$rvm_db_path" ]
then
    if ! grep -q "$rvm_ruby_url" $rvm_db_path; then
        echo "ruby_url=$rvm_ruby_url" > ~/.rvm/user/db
        success 'rvm'
    fi
else
    success "skipped, rvm was replaced `pwd`"
fi
