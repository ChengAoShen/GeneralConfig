#!/usr/bin/env bash
#
# Move configuration between this repo and $HOME. Files are
# copied, not linked: what lives at ~/.config/zsh/.zshrc is a
# real file you can edit in place like any other.
#
#   ./bootstrap.sh install    repo -> $HOME  (default)
#   ./bootstrap.sh collect    $HOME -> repo, ready to commit
#   ./bootstrap.sh install --tools
#   ./bootstrap.sh install --dry-run
#
# Either direction copies only what actually differs, so a run
# that changes nothing says so.

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

CHANGED=0
# mkdir -p is idempotent, but in --dry-run nothing is created, so
# the same directory would otherwise be reported once per file.
# A plain string, not an associative array: macOS ships bash 3.2.
MADE_DIRS=

ensure_dir() {
  local d=$1
  [[ -d $d ]] && return 0
  case " $MADE_DIRS " in *" $d "*) return 0 ;; esac
  MADE_DIRS="$MADE_DIRS $d"
  run mkdir -p "$d"
}

info() { printf '  %s\n' "$*"; CHANGED=1; }
warn() { printf '  ! %s\n' "$*" >&2; }
run()  { if (( DRY_RUN )); then printf '  $ %s\n' "$*"; else "$@"; fi; }
tilde() { printf '~%s' "${1#$HOME}"; }

case "$(uname -s)" in
  Darwin) HOST_DIR=macos ;;
  Linux)  HOST_DIR=linux-server ;;
  *) echo "unsupported platform: $(uname -s)" >&2; exit 1 ;;
esac

echo "==> $MODE   host: $HOST_DIR   repo: $REPO"

# --- One file, either direction ----------------------------------------
# An old install linked these instead of copying them; a leftover
# symlink is replaced rather than written through.

sync_file() {
  local from=$1 to=$2
  [[ -e $from ]] || return 0

  if [[ -L $to ]]; then
    run rm -f "$to"
    info "$(tilde "$to") was a symlink, replacing with a real file"
  elif cmp -s "$from" "$to"; then
    return 0
  fi

  ensure_dir "$(dirname "$to")"
  run cp "$from" "$to"
  info "$(tilde "$to")"
}

# In install mode arguments read repo -> home; collect flips them,
# and skips anything the machine does not actually have.

place() {
  local src=$REPO/$1 dest=$2
  if [[ $MODE == install ]]; then
    sync_file "$src" "$dest"
  else
    [[ -e $dest ]] && sync_file "$dest" "$src"
  fi
  return 0
}

place "common/zsh/.zshenv"    "$HOME/.zshenv"
place "common/zsh/.zshrc"     "$HOME/.config/zsh/.zshrc"
place "common/starship.toml"  "$HOME/.config/starship.toml"
place "common/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"
place "$HOST_DIR/claude/settings.json" "$HOME/.claude/settings.json"

[[ -e $REPO/$HOST_DIR/zsh/.zprofile || $MODE == collect ]] &&
  place "$HOST_DIR/zsh/.zprofile" "$HOME/.config/zsh/.zprofile"

[[ -e $REPO/$HOST_DIR/tmux/local.conf || $MODE == collect ]] &&
  place "$HOST_DIR/tmux/local.conf" "$HOME/.config/tmux/local.conf"

if [[ -d $REPO/$HOST_DIR/fastfetch ]]; then
  for f in "$REPO/$HOST_DIR"/fastfetch/*; do
    place "$HOST_DIR/fastfetch/${f##*/}" "$HOME/.config/fastfetch/${f##*/}"
  done
fi

# tmux reads ~/.tmux.conf before ~/.config/tmux/tmux.conf, so a
# leftover from the old layout would silently win.
if [[ $MODE == install && -f $HOME/.tmux.conf && -f $HOME/.config/tmux/tmux.conf ]]; then
  run rm -f "$HOME/.tmux.conf"
  info "removed ~/.tmux.conf, superseded by ~/.config/tmux/tmux.conf"
fi

# --- conf.d ------------------------------------------------------------
# Assembled from common/ and one host directory. Since the copies
# carry no trace of where they came from, the names this script
# wrote last time are recorded, and a fragment that has since been
# renamed or moved is removed on the next run.

CONF_D=$HOME/.config/zsh/conf.d
MANIFEST=$CONF_D/.installed

if [[ $MODE == install ]]; then
  ensure_dir "$CONF_D"

  wanted=()
  for frag in "$REPO"/common/zsh/conf.d/*.zsh "$REPO/$HOST_DIR"/zsh/conf.d/*.zsh; do
    [[ -e $frag ]] || continue
    wanted+=("${frag##*/}")
    sync_file "$frag" "$CONF_D/${frag##*/}"
  done

  if [[ -f $MANIFEST ]]; then
    while read -r name; do
      [[ -n $name ]] || continue
      [[ " ${wanted[*]} " == *" $name "* ]] && continue
      [[ -e $CONF_D/$name ]] || continue
      run rm -f "$CONF_D/$name"
      info "removed $name, no longer in the repo"
    done < "$MANIFEST"
  fi

  (( DRY_RUN )) || printf '%s\n' "${wanted[@]}" > "$MANIFEST"
else
  for frag in "$REPO"/common/zsh/conf.d/*.zsh "$REPO/$HOST_DIR"/zsh/conf.d/*.zsh; do
    [[ -e $frag ]] || continue
    [[ -e $CONF_D/${frag##*/} ]] && sync_file "$CONF_D/${frag##*/}" "$frag"
  done
fi

if [[ $MODE == collect ]]; then
  (( CHANGED )) || echo "  nothing to collect"
  echo "==> done"
  exit 0
fi

# --- Secrets -----------------------------------------------------------

SECRETS=$HOME/.config/zsh/secrets.zsh
if [[ ! -e $SECRETS ]]; then
  if (( DRY_RUN )); then
    info "would create $(tilde "$SECRETS")"
  else
    mkdir -p "$(dirname "$SECRETS")"
    cat > "$SECRETS" <<'EOF'
# Machine-local, never committed. Export API keys and anything
# else that belongs to this host only.
EOF
    chmod 600 "$SECRETS"
    info "created $(tilde "$SECRETS")"
  fi
fi

# --- zsh plugins -------------------------------------------------------
# Homebrew ships these on macOS; everywhere else they are a clone.

if [[ $HOST_DIR != macos ]]; then
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
# No root on the Linux box, so the CLI tools come from conda. Only
# the wanted binaries are exposed: that environment also carries
# its own openssl and a full set of ncurses utilities, which have
# no business shadowing the system ones.

TOOL_BINS=(zsh starship fzf bat fd delta tmux gh btop atuin just direnv)

if [[ $HOST_DIR != macos && -d $HOME/micromamba/envs/tools/bin ]]; then
  TOOLS_BIN=$HOME/micromamba/envs/tools/bin
  SHIM_DIR=$HOME/.local/share/tools/bin
  ensure_dir "$SHIM_DIR"

  for b in "${TOOL_BINS[@]}"; do
    if [[ ! -x $TOOLS_BIN/$b ]]; then
      warn "not installed in the tools env: $b"
    elif [[ $(readlink "$SHIM_DIR/$b" 2>/dev/null) != "$TOOLS_BIN/$b" ]]; then
      run ln -sfn "$TOOLS_BIN/$b" "$SHIM_DIR/$b"
      info "shim $b"
    fi
  done

  for existing in "$SHIM_DIR"/*; do
    [[ -L $existing ]] || continue
    name=${existing##*/}
    [[ " ${TOOL_BINS[*]} " == *" $name "* ]] && continue
    run rm -f "$existing"
    info "removed shim $name"
  done
fi

# --- Tools -------------------------------------------------------------

if (( WITH_TOOLS )); then
  echo "==> tools"
  if [[ $HOST_DIR == macos ]]; then
    run brew install \
      zsh-autosuggestions zsh-syntax-highlighting starship fzf bat fd \
      eza ripgrep git-delta gh lazygit btop atuin just direnv tmux \
      fastfetch zoxide uv neovim
  else
    MAMBA=${MAMBA_EXE:-$HOME/bin/micromamba}
    if [[ -x $MAMBA ]]; then
      run "$MAMBA" create -y -n tools -c conda-forge \
        zsh starship fzf bat fd-find git-delta tmux gh btop atuin just direnv
      echo "   re-run bootstrap.sh to refresh the shims"
    else
      warn "micromamba not found at $MAMBA; skipping"
    fi
    command -v uv >/dev/null && run uv tool install nvitop
  fi
fi

(( CHANGED )) || echo "  already up to date"
echo "==> done"

if [[ $HOST_DIR != macos ]] && ! grep -q 'exec "$__zsh"' "$HOME/.bashrc" 2>/dev/null; then
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
