if (( $+commands[gpg] )); then
  # general use aliases
  alias glk='gpg -k'    # list public keys
  alias glsk='gpg -K'   # list secret keys
  alias gllk='glk --keyid-format long'    # list public keys with LONG format
  alias gllsk='glsk --keyid-format long'   # list secret keys with LONG format

  # alias gek='gpg -eo' # export public key
fi
