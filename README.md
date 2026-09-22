# GeneralConfig

Shell, prompt and tmux configuration for my machines, split by
operating system — which is where the real difference is, since
Homebrew exists on one side of that line and not the other.

```sh
git clone https://github.com/ChengAoShen/GeneralConfig
./GeneralConfig/bootstrap.sh install --tools
```

## What is here

```
mac/     zshenv  zshrc  zprofile  starship.toml  tmux.conf
         claude-settings.json  fastfetch/
linux/   zshenv  zshrc  starship.toml  tmux.conf
         claude-settings.json
bootstrap.sh   copies one of them into $HOME, picked by uname
```

Each directory is a complete set. `mac/zshrc` is the whole file,
top to bottom, in the order zsh reads it — nothing is assembled
from fragments, and no file has to be read together with another
one to make sense.

The price is that `starship.toml` exists twice. It is the same
prompt on both, so when it changes, change it in both.

A Mac used as a server gets `mac/` — the greeting and the hidden
tmux status bar come with it. If that ever stops being what I
want, that is the moment to split further, not before.

## The two directions

```sh
./bootstrap.sh install    # repo -> $HOME, after a pull
./bootstrap.sh collect    # $HOME -> repo, after editing in place
```

Files are copied, not linked: `~/.config/zsh/.zshrc` is a real
file you can edit like any other, and nothing in `$HOME` points
back here. Both directions copy only what actually differs and
say so; `--dry-run` prints the same without touching anything.

`bootstrap.sh` also clones or pulls the two things that are not
configuration files — the Neovim config below, and, on Linux, the
zsh plugins — and `--tools` installs the CLI toolchain from
Homebrew or, on a machine without root, from conda-forge.

## Secrets

`~/.config/zsh/secrets.zsh` is created by `bootstrap.sh`, mode
600, and is not in this repo. API keys go there and nowhere else
— in particular not in `zshrc`, which `collect` would copy
straight into a commit.

## Neovim

Its own repo, [ChengAoShen/nvim][nvim], cloned to `~/.config/nvim`
by `bootstrap.sh` and updated with it. Neovim itself is managed by
[bob][bob]; keep machines on the same version with `bob use`.

## Why the Linux side is different

In practice `linux/` means one machine: the shared lab GPU box.
Each of these follows from something about it, not from drift.

- **No greeting.** `fastfetch` is macOS-only; a banner on every
  `ssh host cmd` is noise.
- **tmux status bar on, off on macOS.** Sessions there outlive
  the connection and there are usually several.
- **zsh is not the login shell.** `chsh` only accepts shells in
  `/etc/shells`, which needs root. A guarded `exec zsh` in
  `~/.bashrc` hands off instead, skipping non-interactive
  sessions so scp, rsync and VS Code Remote keep working.
- **Caches point at `/data`.** `$HOME` shares a 1.8T root volume
  with the rest of the lab; `/data` has its own 14T NVMe. Guarded
  on `/data/$USER` existing, so the file still works elsewhere.
- **CLI tools come from a conda env that is never activated.**
  Only the wanted binaries are symlinked into
  `~/.local/share/tools/bin`; the environment also carries its own
  openssl and ncurses utilities, which should not shadow the
  system ones, and its libstdc++ should not shadow the one a CUDA
  build expects.

[nvim]: https://github.com/ChengAoShen/nvim
[bob]: https://github.com/MordechaiHadad/bob
