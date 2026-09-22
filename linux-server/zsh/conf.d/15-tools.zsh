# The machine has no root, so the CLI tools that would normally
# come from apt live in a micromamba environment instead.
#
# That environment's bin/ is not what goes on PATH: alongside the
# tools it carries its own openssl and a full set of ncurses
# utilities, which have no business shadowing the system ones.
# bootstrap.sh links just the wanted binaries into a shim
# directory, and only that is exposed.
#
# It goes first because some of these -- tmux and zsh especially
# -- exist on the system too, in versions old enough to choke on
# this repo's config. Nothing in it collides with ~/.cargo/bin or
# ~/.local/bin.

path=($HOME/.local/share/tools/bin $path)
