# Each one is guarded: a machine missing a tool still gets a
# working shell instead of an error on every prompt.

export _ZO_DOCTOR=0

(( $+commands[starship] )) && eval "$(starship init zsh)"
(( $+commands[zoxide]   )) && eval "$(zoxide init --cmd cd zsh)"
(( $+commands[fzf]      )) && source <(fzf --zsh)
(( $+commands[direnv]   )) && eval "$(direnv hook zsh)"

# atuin rebinds Ctrl-R to its own searchable history. Up-arrow is
# left alone so it keeps walking this session's history.
(( $+commands[atuin] )) && eval "$(atuin init zsh --disable-up-arrow)"
