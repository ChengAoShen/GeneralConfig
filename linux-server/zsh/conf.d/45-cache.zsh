# $HOME sits on a 1.8T root volume shared with everyone else,
# while /data has its own 14T NVMe. Anything that grows without
# bound belongs there.

export XDG_CACHE_HOME=/data/cshen20/cache

export HF_HOME=$XDG_CACHE_HOME/huggingface
export TORCH_HOME=$XDG_CACHE_HOME/torch
export UV_CACHE_DIR=$XDG_CACHE_HOME/uv
export PIP_CACHE_DIR=$XDG_CACHE_HOME/pip
export TRITON_CACHE_DIR=$XDG_CACHE_HOME/triton
