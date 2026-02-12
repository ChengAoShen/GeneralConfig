#!/usr/bin/env bash
set -euo pipefail

if ! command -v rustup >/dev/null 2>&1; then
  curl https://sh.rustup.rs -sSf | sh
fi

if [[ -f "$HOME/.cargo/env" ]]; then
  source "$HOME/.cargo/env"
fi

if ! command -v node >/dev/null 2>&1; then
  if [[ ! -d "$HOME/.nvm" ]]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
  fi

  if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
    source "$HOME/.nvm/nvm.sh"
  fi

  if command -v nvm >/dev/null 2>&1; then
    nvm install --lts
    nvm use --lts
  else
    printf 'nvm is not available; install Node.js manually.\n'
  fi
fi

# Install useful command
if ! command -v zoxide >/dev/null 2>&1; then
  cargo install zoxide
fi

if ! command -v eza >/dev/null 2>&1; then
  cargo install eza
fi

if ! command -v bob >/dev/null 2>&1; then
  cargo install bob-nvim
fi

if [[ ! -d "$HOME/.local/share/bob" ]]; then
  bob install stable
  bob use stable
fi

# Add aliases and zoxide initialization to shell config
if [[ "$SHELL" == */zsh ]]; then
  shell_config="$HOME/.zshrc"
  zoxide_init="eval \"\$(zoxide init zsh --cmd cd)\""
else
  shell_config="$HOME/.bashrc"
  zoxide_init="eval \"\$(zoxide init bash --cmd cd)\""
fi

# Add aliases and zoxide init if not already present
if ! grep -q "alias cat='bat'" "$shell_config" 2>/dev/null; then
  cat >> "$shell_config" << 'EOF'

# QuickSetup aliases
alias cat='bat'
alias ls='eza --icons'
alias ll='eza -l --icons --git --group-directories-first --time-style=long-iso'
alias la='eza -la --icons --git --group-directories-first --time-style=long-iso'
alias lt='eza --tree --level=2 --icons'
EOF
fi

if ! grep -q "zoxide init" "$shell_config" 2>/dev/null; then
  echo "$zoxide_init" >> "$shell_config"
fi
