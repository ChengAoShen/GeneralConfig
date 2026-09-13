# Generic zsh config shared across machines. Machine-specific
# blocks (Homebrew, CUDA, TeX Live, Android SDK, WSL) live in
# the local ~/.zshrc / ~/.zprofile and are deliberately absent.

export EDITOR=nvim VISUAL=nvim


# --- PATH ---------------------------------------------------
# One assignment, highest precedence first.

typeset -U path

path=(
  $HOME/.local/share/bob/nvim-bin   # bob-managed Neovim
  $HOME/.cargo/bin                  # cargo-installed binaries
  $HOME/.local/bin                  # personal scripts
  $path
)


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


# --- Completion ---------------------------------------------
# Selectable menu, case-insensitive matching, grouped sections.

autoload -Uz compinit
compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'


# --- Aliases ------------------------------------------------
# The eza ones chain off `ls`, so its flags are set in one
# place. `cat` is deliberately left as real cat -- use `c`.

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


# --- Tool integrations --------------------------------------
# Starship prompt, zoxide smart cd, fzf. Syntax highlighting
# must be sourced last. Plugin paths differ by package manager:
# Homebrew on macOS, /usr/share on Linux.

export _ZO_DOCTOR=0

eval "$(starship init zsh)"
eval "$(zoxide init --cmd cd zsh)"
source <(fzf --zsh)

for _plugdir in "${HOMEBREW_PREFIX:-/opt/homebrew}/share" /usr/share/zsh/plugins /usr/share; do
  [[ -f $_plugdir/zsh-autosuggestions/zsh-autosuggestions.zsh ]] || continue
  source $_plugdir/zsh-autosuggestions/zsh-autosuggestions.zsh
  source $_plugdir/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  break
done
unset _plugdir


# --- Greeting -----------------------------------------------

fastfetch
