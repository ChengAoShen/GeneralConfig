# Research environments. `conda` is aliased because muscle memory
# is stronger than the rename.

export MAMBA_EXE="$HOME/bin/micromamba"
export MAMBA_ROOT_PREFIX="$HOME/micromamba"

if [[ -x $MAMBA_EXE ]]; then
  eval "$("$MAMBA_EXE" shell hook --shell zsh --root-prefix "$MAMBA_ROOT_PREFIX" 2>/dev/null)"
  alias conda=micromamba
fi
