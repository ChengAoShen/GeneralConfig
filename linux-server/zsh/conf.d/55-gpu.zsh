# Eight cards shared with the rest of the lab, so the question is
# never just "how busy" but "busy with whose job".

alias gpu='nvitop'

gpus() {
  nvidia-smi --query-gpu=index,utilization.gpu,memory.used,memory.total \
             --format=csv,noheader,nounits |
    awk -F', *' '{printf "GPU %s  %3s%%  %6s / %6s MiB\n", $1, $2, $3, $4}'

  local pid mem
  echo
  nvidia-smi --query-compute-apps=pid,used_memory \
             --format=csv,noheader,nounits |
  while IFS=', ' read -r pid mem; do
    printf "  %-8s %-10s %6s MiB  %s\n" \
      "$pid" "$(ps -o user= -p $pid 2>/dev/null)" "$mem" \
      "$(ps -o comm= -p $pid 2>/dev/null)"
  done
}
