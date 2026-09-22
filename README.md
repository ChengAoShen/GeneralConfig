# GeneralConfig

Shell, prompt, tmux and editor configuration for the three
machines I work on.

```sh
git clone https://github.com/ChengAoShen/GeneralConfig
./GeneralConfig/bootstrap.sh install --tools
```

Files are **copied** into place, not linked: `~/.config/zsh/.zshrc`
is a real file you can edit like any other, and nothing in `$HOME`
points back here. The repo is the place changes are kept and
carried between machines, not the place they live.

So the loop is two-way:

```sh
./bootstrap.sh install   # repo -> $HOME, after a pull
./bootstrap.sh collect   # $HOME -> repo, after editing in place
```

Both copy only what actually differs and say so; `--dry-run`
prints the same without touching anything.

## The machines

| | role | shell comes from |
|---|---|---|
| MacBook Pro | daily driver, Android/Tauri builds | Homebrew |
| Mac mini | home server over Tailscale | Homebrew |
| UH_Public | shared lab GPU box, 8×RTX 6000 Ada, **no root** | micromamba |

## Layout

```
common/        everything that is true on every machine
macos/         Homebrew, JDK/Android SDK, fastfetch greeting
linux-server/  micromamba, nvm, GPU helpers, cache redirection
bootstrap.sh   links the above into $HOME
```

`~/.config/zsh/conf.d/` is assembled from `common/` and exactly
one host directory. Since the installed copies carry no trace of
where they came from, `install` records what it wrote in
`conf.d/.installed`, and drops a fragment that has since been
renamed or removed upstream. Fragments are sourced in filename
order, and the numbers leave room for a host file to slot between
two shared ones:

| range | for |
|---|---|
| `00-19` | environment later files depend on — PATH, shell options |
| `20-39` | language toolchains — conda, node, Android |
| `40-59` | aliases, caches, completion |
| `60-69` | prompt and tool integrations |
| `70-79` | zsh plugins; syntax highlighting has to be last |
| `80-89` | greeting |

Everything in `60-integrations.zsh` is guarded by a `commands`
check, so a machine missing a tool still gets a working shell.

## Secrets

`~/.config/zsh/secrets.zsh` is created by `bootstrap.sh`, mode
600, and is in `.gitignore`. API keys go there and nowhere else —
in particular not in a `conf.d` fragment, which `collect` would
copy straight into a commit.

## Deliberate differences

Things that look like drift but are not:

- **The server has no greeting.** `fastfetch` is macOS-only: a
  banner on every `ssh host cmd` is noise, and it draws an image
  the remote terminal may not speak.
- **The server shows a tmux status bar, the laptop does not.**
  Sessions there outlive the connection and there are usually
  several, so their names have to be visible.
- **zsh is not the login shell on UH_Public.** `chsh` only
  accepts shells listed in `/etc/shells`, which needs root. A
  guarded `exec zsh` in `~/.bashrc` hands off instead, skipping
  non-interactive sessions so scp, rsync and VS Code Remote keep
  working.
- **Caches on UH_Public point at `/data`.** `$HOME` shares a
  1.8T root volume with the rest of the lab; `/data` has its own
  14T NVMe.
- **The `tools` conda environment is never activated**, only
  appended to PATH, so its libstdc++ cannot shadow the one a CUDA
  build expects.

## Neovim

Not here — it is its own repo, [ChengAoShen/nvim][nvim], cloned
to `~/.config/nvim`. Update with `git pull`, never by copying
files between machines. Neovim itself is managed by [bob][bob];
keep the machines on the same version with `bob use <version>`.

[nvim]: https://github.com/ChengAoShen/nvim
[bob]: https://github.com/MordechaiHadad/bob
