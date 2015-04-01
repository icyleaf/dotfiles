#!/usr/bin/env bash
#
# Git
source functions/_bash

if test ! $(which tig)
then
  info 'install git tool: [tig]'
  brew install tig
  success "git tool: [tig] installed"
fi

if test ! $(which kdiff3)
then
  info 'install git tool: [kdif3]'
  brew install kdif3
  success "git tool: [kdif3] installed"
fi

success 'git installed'