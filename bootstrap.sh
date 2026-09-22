#!/usr/bin/env bash
#
# Move configuration between this repo and $HOME.
#
#   ./bootstrap.sh install              repo -> $HOME
#   ./bootstrap.sh collect              $HOME -> repo, ready to commit
#   ./bootstrap.sh install --tools      also install the CLI tools
#   ./bootstrap.sh install --dry-run
#
# mac/ or linux/ is chosen by uname. The split is along the one
# line that actually matters: Homebrew exists on one side of it
# and not the other.
#
# Files are copied, not linked. What lives at ~/.config/zsh/.zshrc
# is a real file you can edit in place like any other; the repo is
# where changes are kept and carried between machines, not where
# they live.

set -euo pipefail

REPO=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
MODE=install
DRY_RUN=0
WITH_TOOLS=0

for arg in "$@"; do
  case $arg in
    install|collect) MODE=$arg ;;
    --dry-run) DRY_RUN=1 ;;
    --tools)   WITH_TOOLS=1 ;;
    *) echo "unknown argument: $arg" >&2; exit 2 ;;
  esac
done

case "$(uname -s)" in
  Darwin) KIND=mac ;;
  Linux)  KIND=linux ;;
  *) echo "unsupported platform: $(uname -s)" >&2; exit 1 ;;
esac

CHANGED=0

# bash 4.3+ tilde-expands the replacement in ${var/#pat/~}, which
# would print the full path back; do the substitution by hand.
tilde() { case $1 in "$HOME"/*) printf '~%s' "${1#$HOME}" ;; *) printf '%s' "$1" ;; esac; }

info() { printf '  %s\n' "$*"; CHANGED=1; }
warn() { printf '  ! %s\n' "$*" >&2; }
run()  { if (( DRY_RUN )); then printf '  $ %s\n' "$*"; else "$@"; fi; }

echo "==> $KIND $MODE   repo: $REPO"

# --- The file list -----------------------------------------------------
# "<path in repo>  <path in $HOME>", one per line. This is the whole
# mapping; there is nothing assembled or generated anywhere else.

FILES="
zshenv                    .zshenv
zshrc                     .config/zsh/.zshrc
starship.toml             .config/starship.toml
tmux.conf                 .config/tmux/tmux.conf
claude-settings.json      .claude/settings.json
"

if [[ $KIND == mac ]]; then
  FILES="$FILES
zprofile                  .config/zsh/.zprofile
fastfetch/config.jsonc    .config/fastfetch/config.jsonc
fastfetch/marin.png       .config/fastfetch/marin.png
"
fi

# An older layout linked these instead of copying them, and put
# tmux.conf at the path tmux prefers, where it would still win.
for stale in "$HOME/.tmux.conf" "$HOME/.config/zsh/conf.d"; do
  if [[ $MODE == install && -e $stale ]]; then
    run rm -rf "$stale"
    info "removed $(tilde "$stale"), left over from the old layout"
  fi
done

while read -r src dest; do
  [[ -n $src ]] || continue
  from=$REPO/$KIND/$src
  to=$HOME/$dest
  [[ $MODE == collect ]] && { tmp=$from; from=$to; to=$tmp; }

  [[ -e $from ]] || { [[ $MODE == install ]] && warn "missing in repo: $KIND/$src"; continue; }
  [[ -L $to ]] && run rm -f "$to"
  cmp -s "$from" "$to" 2>/dev/null && continue

  [[ -d $(dirname "$to") ]] || run mkdir -p "$(dirname "$to")"
  run cp "$from" "$to"
  info "$(tilde "$to")"
done <<< "$FILES"

if [[ $MODE == collect ]]; then
  (( CHANGED )) || echo "  nothing to collect"
  echo "==> done"
  exit 0
fi

# --- Secrets -----------------------------------------------------------
# Kept out of the repo, and out of .zshrc, which collect would
# copy straight into a commit.

SECRETS=$HOME/.config/zsh/secrets.zsh
if [[ ! -e $SECRETS ]]; then
  if (( DRY_RUN )); then
    info "would create ~/.config/zsh/secrets.zsh"
  else
    mkdir -p "$(dirname "$SECRETS")"
    printf '%s\n' \
      '# Machine-local, never committed. Export API keys and' \
      '# anything else that belongs to this host only.' > "$SECRETS"
    chmod 600 "$SECRETS"
    info "created ~/.config/zsh/secrets.zsh"
  fi
fi

# --- Neovim ------------------------------------------------------------
# Its own repo, not a copy of anything kept here.

NVIM_REPO=https://github.com/ChengAoShen/nvim
if [[ -d $HOME/.config/nvim/.git ]]; then
  run git -C "$HOME/.config/nvim" pull --quiet --ff-only
elif [[ -e $HOME/.config/nvim ]]; then
  warn "~/.config/nvim exists but is not a git clone; leaving it alone"
else
  run git clone --quiet "$NVIM_REPO" "$HOME/.config/nvim"
  info "cloned nvim config"
fi

# --- zsh plugins -------------------------------------------------------
# Homebrew ships these on macOS; the GPU box has no root, so
# they are a plain clone.

if [[ $KIND == linux ]]; then
  PLUGIN_DIR=$HOME/.local/share/zsh/plugins
  for repo in zsh-users/zsh-autosuggestions zsh-users/zsh-syntax-highlighting; do
    name=${repo##*/}
    if [[ -d $PLUGIN_DIR/$name ]]; then
      run git -C "$PLUGIN_DIR/$name" pull --quiet --ff-only
    else
      run mkdir -p "$PLUGIN_DIR"
      run git clone --quiet --depth 1 "https://github.com/$repo" "$PLUGIN_DIR/$name"
      info "cloned $name"
    fi
  done
fi

# --- Tool shims --------------------------------------------------------
# No root on the lab box, so the CLI tools come from conda. Only the
# wanted binaries are exposed: that environment also carries its own
# openssl and a full set of ncurses utilities, which have no business
# shadowing the system ones.

TOOLS="zsh starship fzf bat fd delta tmux gh btop atuin just direnv"

if [[ $KIND == linux && -d $HOME/micromamba/envs/tools/bin ]]; then
  TOOLS_BIN=$HOME/micromamba/envs/tools/bin
  SHIM_DIR=$HOME/.local/share/tools/bin
  [[ -d $SHIM_DIR ]] || run mkdir -p "$SHIM_DIR"

  for b in $TOOLS; do
    if [[ ! -x $TOOLS_BIN/$b ]]; then
      warn "not installed in the tools env: $b"
    elif [[ $(readlink "$SHIM_DIR/$b" 2>/dev/null) != "$TOOLS_BIN/$b" ]]; then
      run ln -sfn "$TOOLS_BIN/$b" "$SHIM_DIR/$b"
      info "shim $b"
    fi
  done

  for existing in "$SHIM_DIR"/*; do
    [[ -L $existing ]] || continue
    case " $TOOLS " in *" ${existing##*/} "*) continue ;; esac
    run rm -f "$existing"
    info "removed shim ${existing##*/}"
  done
fi

# --- Installing the tools themselves -----------------------------------

if (( WITH_TOOLS )); then
  echo "==> tools"
  if [[ $KIND == mac ]]; then
    run brew install \
      zsh-autosuggestions zsh-syntax-highlighting starship fzf bat fd \
      eza ripgrep git-delta gh lazygit btop just direnv tmux \
      fastfetch zoxide uv neovim
  else
    MAMBA=${MAMBA_EXE:-$HOME/bin/micromamba}
    if [[ -x $MAMBA ]]; then
      run "$MAMBA" create -y -n tools -c conda-forge \
        zsh starship fzf bat fd-find git-delta tmux gh btop atuin just direnv
      echo "   re-run without --tools to refresh the shims"
    else
      warn "micromamba not found at $MAMBA; skipping"
    fi
    command -v uv >/dev/null && run uv tool install nvitop
  fi
fi

(( CHANGED )) || echo "  already up to date"
echo "==> done"

# --- The one thing left by hand ----------------------------------------

if [[ $KIND == linux ]] && ! grep -q 'exec "$__zsh"' "$HOME/.bashrc" 2>/dev/null; then
  cat <<'EOF'

  zsh is not the login shell yet. chsh only accepts shells listed
  in /etc/shells, which needs root, so bash hands off instead.
  Append to ~/.bashrc, then open a SECOND ssh session to verify
  before closing this one:

      case $- in *i*)
          __zsh=$HOME/.local/share/tools/bin/zsh
          if [ -z "$ZSH_VERSION" ] && [ "$TERM" != dumb ] \
             && [ -z "$VSCODE_INJECTION" ] && [ -x "$__zsh" ]; then
              exec "$__zsh" -l
          fi
          unset __zsh
          ;;
      esac
EOF
fi
