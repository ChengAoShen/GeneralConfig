# Selectable menu, case-insensitive matching, grouped sections.
#
# compinit's security check walks every directory in fpath, which
# is the slow part of zsh startup. Run it once a day and trust
# the cached dump in between (-C).

autoload -Uz compinit

_zdump=${ZDOTDIR:-$HOME}/.zcompdump
if [[ -f $_zdump && -z $_zdump(#qN.mh+24) ]]; then
  compinit -C -d $_zdump
else
  compinit -d $_zdump
fi
unset _zdump

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
