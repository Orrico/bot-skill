#!/usr/bin/env bash
# usage: delegate-usage.sh <transcripts dir>... — for each Claude Code session that a
# /bot delegate ran (its first user message reads a role file and asks for one status line),
# prints: model, requests, the first request's context (input + cache write + cache read),
# the session's input and output tokens, and the share of the input that is the fixed context
# re-sent on each request. Transcripts are ~/.claude/projects/<dir>/*.jsonl. A transcript logs
# each content block of one response as its own entry, with the response's usage repeated:
# requests are counted once per message id. Reads only.
set -u
[ $# -ge 1 ] || { echo "usage: delegate-usage.sh <transcripts dir>..." >&2; exit 2; }
printf '%-18s %5s %8s %11s %9s %6s %s\n' model reqs fixed input output fixed% roles
for d in "$@"; do
  for f in "$d"/*.jsonl; do
    [ -e "$f" ] || continue
    first=$(jq -r 'select(.type == "user") | .message.content
      | if type == "string" then . else (.[0].text // "") end' "$f" 2>/dev/null | head -1)
    case "$first" in Read\ /*roles/*Answer\ with\ one\ status\ line*) ;; *) continue;; esac
    jq -s -r --arg roles "$(grep -oE 'roles/[A-Z]+\.md' <<<"$first" | sed 's|roles/||; s|\.md||' | paste -sd+)" '
      [.[] | select(.type == "assistant")] | group_by(.message.id) | map(.[0])
      | sort_by(.timestamp) | map(.message) as $m
      | ($m | map(.usage | .input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens)) as $in
      | ($m[0].model) as $model | ($m | length) as $n | $in[0] as $fixed | ($in | add) as $total
      | "\($model)\t\($n)\t\($fixed)\t\($total)\t\($m | map(.usage.output_tokens) | add)\t\(($fixed * $n * 100 / $total) | floor)%\t\($roles)"' "$f"
  done
done | awk -F'\t' '{printf "%-18s %5s %8s %11s %9s %6s %s\n", $1, $2, $3, $4, $5, $6, $7}'
