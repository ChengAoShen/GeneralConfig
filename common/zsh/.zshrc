# A loader, nothing else. The real configuration lives in
# conf.d/, which bootstrap.sh fills with symlinks from common/
# plus the one host directory that applies to this machine. Files
# are sourced in filename order, and the numbers carve out ranges
# so a host file can slot in between two shared ones:
#
#   00-19  environment later files depend on (PATH, shell options)
#   20-39  language toolchains (conda, node, android)
#   40-59  aliases, caches, completion
#   60-69  prompt and tool integrations
#   70-79  zsh plugins -- syntax highlighting has to come last
#   80-89  greeting

for _f in ${ZDOTDIR:-$HOME/.config/zsh}/conf.d/*.zsh(N); do
  source $_f
done
unset _f

# API keys and anything else that must not reach the repo. See
# the README for what belongs here.
[[ -r ${ZDOTDIR:-$HOME/.config/zsh}/secrets.zsh ]] &&
  source ${ZDOTDIR:-$HOME/.config/zsh}/secrets.zsh
