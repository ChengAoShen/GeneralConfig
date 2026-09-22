# The eza ones chain off `ls`, so its flags are set in one place.
# `cat` is deliberately left as real cat -- use `c`.

alias ls='eza --icons --group-directories-first'
alias ll='ls -l --git'
alias la='ls -la --git'
alias lt='ls --tree --level=2'
alias lta='lt -a'

alias c='bat --paging=never --style=plain'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias g='git'
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate'

alias vi='nvim'
