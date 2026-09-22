# Sourcing nvm.sh costs roughly a third of a second on every
# shell. With a single version installed it is cheaper to put its
# bin on PATH directly and pull nvm in only if it is ever called.

export NVM_DIR="$HOME/.nvm"

() {
  local -a versions
  versions=($NVM_DIR/versions/node/*(N/om))   # newest first
  (( $#versions )) && path+=($versions[1]/bin)
}

nvm() {
  unfunction nvm
  source $NVM_DIR/nvm.sh
  nvm "$@"
}
