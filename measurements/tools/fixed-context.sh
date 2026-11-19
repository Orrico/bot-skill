#!/usr/bin/env bash
# usage: fixed-context.sh <root> [model] — measures the context a delegate re-sends on each
# request: runs `claude -p` twice from <root> with a one-word answer, once as delegate.sh ran it
# before 24fdced and once with the tools of a role alone, and prints each run's input tokens
# (input + cache write + cache read) and cost at API prices. Spends two short calls of the
# model (default haiku) from the user's quota.
set -u
root=$(cd "${1:?usage: fixed-context.sh <root> [model]}" && pwd); model=${2:-haiku}
lean=(--tools "Read,Edit,Write,Bash,Grep,Glob" --strict-mcp-config --disable-slash-commands)
for run in full lean; do
  extra=(); [ $run = lean ] && extra=("${lean[@]}")
  (cd "$root" && claude -p "Answer with the single word: ok" --model "$model" \
    --permission-mode auto --output-format json "${extra[@]}") |
    jq -r --arg run $run '"\($run): \(.usage.input_tokens + .usage.cache_creation_input_tokens
      + .usage.cache_read_input_tokens) tokens in, $\(.total_cost_usd)"'
done
