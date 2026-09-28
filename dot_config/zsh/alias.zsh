alias vim="nvim"

alias flushdns='sudo killall -HUP mDNSResponder'
alias nns="sudo lsof -i -P"
alias nnc="lsof -Pni4 | grep LISTEN"
alias moss='mosh --server=`which mosh-server`'
alias ox='open *.xcodeproj'
alias ow='open *.xcworkspace'

alias reload='source ~/.zshrc && echo zshrc reloaded.'
alias zshrc='vim ~/.zshrc'

alias fuckapp='sudo xattr -r -d com.apple.quarantine'

alias sshig="ssh -o StrictHostKeychecking=no -o UserKnownHostsFile=/dev/null"

if (( $+commands[wl-copy] )); then
  alias pbcopy='wl-copy'
  alias pbpaste='wl-paste'
fi

if (( $+commands[xsel] )); then
  alias pbcopy='xsel --clipboard --input'
  alias pbpaste='xsel --clipboard --output'
fi

if (( $+commands[xclip] )); then
  alias pbcopy='xclip -selection clipboard'
  alias pbpaste='xclip -selection clipboard -o'
fi

[[ "$TERM" == "xterm-kitty" ]] && alias ssh="TERM=xterm-256color ssh"
