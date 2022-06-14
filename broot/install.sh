#!/usr/bin/env bash
#
# broot

source functions/_lib.sh

BROOT_PATH=$(which broot)

info "Installing br"
if test ! "$BROOT_PATH"; then
  fail "broot was not installed, run brew/install.sh to install first."
fi

# https://dystroy.org/broot/install-br/
$BROOT_PATH --install
success "br bundle installed"
