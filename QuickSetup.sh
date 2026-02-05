#!/usr/bin/env bash
set -euo pipefail

append_if_missing() {
  local line="$1"
  local file="$2"

  if [[ ! -f "$file" ]]; then
    touch "$file"
  fi

  if ! grep -Fqx "$line" "$file"; then
    printf '\n%s\n' "$line" >> "$file"
  fi
}

if ! command -v rustup >/dev/null 2>&1; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

if [[ -f "$HOME/.cargo/env" ]]; then
  # shellcheck source=/dev/null
  source "$HOME/.cargo/env"
fi

if ! command -v node >/dev/null 2>&1; then
  if [[ ! -d "$HOME/.nvm" ]]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  fi

  if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
    # shellcheck source=/dev/null
    source "$HOME/.nvm/nvm.sh"
  fi

  if command -v nvm >/dev/null 2>&1; then
    nvm install --lts
    nvm use --lts
  else
    printf 'nvm is not available; install Node.js manually.\n'
  fi
fi

# Install usefule command
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

append_if_missing 'eza --icons' "$HOME/.bashrc"
append_if_missing 'eza -l --icons --git --group-directories-first --time-style=long-iso' "$HOME/.bashrc"
append_if_missing 'eza -la --icons --git --group-directories-first --time-style=long-iso' "$HOME/.bashrc"
append_if_missing 'eza --tree --level=2 --icons' "$HOME/.bashrc"
append_if_missing 'eval "$(zoxide init bash --cmd cd)"' "$HOME/.bashrc"
append_if_missing 'export PATH="$HOME/.local/share/bob/nvim-bin:$PATH"' "$HOME/.bashrc"


printf '\nSetup complete. Restart your shell or run: source ~/.bashrc\n'

cp .conf/tmux.conf ~/.config/tmux
