export EDITOR=nvim VISUAL=nvim


# --- History ------------------------------------------------
# Persist 50k commands, shared across sessions, deduped, and
# skipping anything typed with a leading space.

HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE \
       HIST_REDUCE_BLANKS EXTENDED_HISTORY


# --- Shell behavior -----------------------------------------
# Bare directory name cds into it, with a directory stack.

setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS INTERACTIVE_COMMENTS NO_BEEP
