# Homebrew environment: PATH, MANPATH, INFOPATH, and the fpath
# entry brew-installed completions live in. Login shells only, so
# it runs once, before .zshrc.

eval "$(/opt/homebrew/bin/brew shellenv zsh)"
