# Autosuggestions first, then syntax highlighting, and both after
# everything else -- highlighting wraps widgets and has to see the
# final set. Where they live depends on how they were installed:
# Homebrew on macOS, a plain git clone on a machine without root.

for _d in \
  ${HOMEBREW_PREFIX:-/opt/homebrew}/share \
  $HOME/.local/share/zsh/plugins \
  /usr/share/zsh/plugins \
  /usr/share
do
  [[ -r $_d/zsh-autosuggestions/zsh-autosuggestions.zsh ]] || continue
  source $_d/zsh-autosuggestions/zsh-autosuggestions.zsh
  source $_d/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  break
done
unset _d
