#!/usr/bin/env bash
#
# SpaceVim
source functions/_bash

# Install SpaceVim
curl -sLf https://spacevim.org/install.sh | bash

# Create bundle dir
#mkdir -p ~/.vim/bundle
#
## Install vundle
#if ! [ -d ~/.vim/bundle/vundle ]
#then
#  git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle
#fi
#
## Install vim plugins from .vimrc
#vim +BundleInstall +BundleClean +qall
#
#success "vim/vundle/bundles installed"
