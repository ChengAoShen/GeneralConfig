# .zprofile already did this for login shells; the fallback covers
# the non-login case. It has to land before 10-path and before
# compinit, since shellenv also runs path_helper and adds brew's
# completions to fpath.

[[ -n $HOMEBREW_PREFIX ]] || eval "$(/opt/homebrew/bin/brew shellenv zsh)"
