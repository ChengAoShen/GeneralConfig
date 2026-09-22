# One assignment, highest precedence first. Host files that run
# after this one prepend with `path=(... $path)` when they need
# priority, and append with `path+=(...)` when they must not
# shadow anything already there.

typeset -U path

path=(
  $HOME/.local/share/bob/nvim-bin   # bob-managed Neovim
  $HOME/.cargo/bin                  # cargo-installed binaries
  $HOME/.local/bin                  # personal scripts, uv tools
  $path
)
