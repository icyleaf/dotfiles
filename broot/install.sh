#!/usr/bin/env bash
#
# broot

source functions/_lib.sh

info "Installing br"
if test ! $(which broot); then
  fail "broot was not installed, run brew/install.sh to install first."
fi

if [ -z "$(ls /usr/local/bin | grep -i broot)" ]; then
  ln -s /usr/local/Cellar/broot/0.1.0/bin/broot /usr/local/bin/broot
else
  echo "broot was installed"
fi

# https://dystroy.org/broot/install-br/
broot --install
success "br bundle installed"
