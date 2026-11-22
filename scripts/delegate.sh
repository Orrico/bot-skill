#!/usr/bin/env bash
# usage: delegate.sh <root> [review] <TASK-nnn | --<kind> <subject>> <claude|agy> <model|tier|auto>
# [-e <effort>] [-g <gap>] [-t <minutes>] [-w <dir>]... [-n] — runs a TASK's executor, or a
# REVIEWER, in another CLI, headless, from the project's root. Without `review`: executes the TASK
# (-g sends it back with that gap, refused once its result holds a `## Send-back 5`). With
# `review`: reviews the delivery of a TASK in state delivered, or reviews by a kind of
# roles/reviews/ on a subject. <model|tier|auto> accepts a literal model ID, a tier name of
# models.md, or `auto` (reads `tier:` / `critical_zone:` from the TASK, or derives from --<kind>).
# -e sets or overrides reasoning effort (low|medium|high|xhigh|max). -n resolves and validates
# without running. Prints the delegate's status line, what it wrote, the log paths, and the
# session's tokens and turns; exits 1 when it wrote nothing. claude runs with the tools of a role's
# work alone (no web, MCP, skills or background tasks); agy runs with slash commands disabled and
# JSON output. -w gives the delegate a directory outside the project to work in, its .git read-only
# under agy
set -eu
usage="usage: delegate.sh <root> [review] <TASK-nnn | --<kind> <subject>> <claude|agy> <model|tier|auto> [-e <effort>] [-g <gap>] [-t <minutes>] [-w <dir>]... [-n]"
root=$(cd "${1:?$usage}" && pwd); shift
bot=$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)
roles="$bot/roles"
mode=execute id="" kind="" subject=""
[ "${1:-}" = review ] && { mode=review; shift; }
case "${1:?$usage}" in
  --*) [ $mode = review ] || { echo "$usage" >&2; exit 2; }; kind=${1#--} subject=${2:?$usage}; shift 2;;
  *) id=$1; shift;;
esac
cli=${1:?$usage} model=${2:?$usage}; shift 2
effort="" gap="" minutes=60 dry_run=0 dirs=()
while [ $# -gt 0 ]; do
  case "$1" in
    -e) case "${2:-}" in
          low|medium|high|xhigh|max) effort=$2; shift 2;;
          *) echo "-e: effort must be low, medium, high, xhigh or max" >&2; exit 2;;
        esac;;
    -g) gap=$2; shift 2;;
    -n) dry_run=1; shift;;
    -t) minutes=$2; shift 2;;
    -w) [ -d "${2:-}" ] || { echo "-w: no directory ${2:-}" >&2; exit 2; }
      d=$(cd "$2" && pwd)
      case "$d/" in "$root"/*) echo "-w: $d is inside the project" >&2; exit 2;; esac
      dirs+=("$d"); shift 2;;
    *) echo "$usage" >&2; exit 2;;
  esac
done
[ -z "$gap" ] || [ $mode = execute ] || { echo "-g is for an execution, not a review" >&2; exit 2; }
case "$cli" in claude|agy) ;; *) echo "cli '$cli' is not claude or agy" >&2; exit 2;; esac

if [ -n "$id" ]; then
  task="$root/.bot/tasks/$id.md"
  [ -f "$task" ] || { echo "no $task" >&2; exit 2; }
  field() { sed -n -E "s/^$1:[[:space:]]*//p" "$task" | head -1; }
  state="$(field state)$(field estado)"
fi

resolve_tier() { # <tier> <cli> -> prints "model|effort|review_tier" from models.md
  awk -F'|' -v t="$1" -v c="$2" '
    /^\|/ {
      k = $2; gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", k)
      if (k != t) next
      cell = (c == "claude" ? $3 : $4)
      n = 0
      while (match(cell, /`[^`]+`/)) {
        tok[++n] = substr(cell, RSTART + 1, RLENGTH - 2)
        cell = substr(cell, RSTART + RLENGTH)
      }
      rev = ""
      if (NF >= 8) {
        r = $7; gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", r)
        if (r ~ /^review-/) rev = r
      }
      eff = (c == "claude" && n >= 2 ? tok[2] : "")
      printf "%s|%s|%s\n", tok[1], eff, rev
      exit 0
    }' "$bot/models.md"
}

tier=""
case "$model" in
  auto)
    if [ "$mode" = execute ]; then
      tier=$(field tier)
      case "$tier" in
        trivial|standard|complex|deep) ;;
        *) echo "$id: tier '$tier' is not trivial, standard, complex or deep" >&2; exit 2;;
      esac
    elif [ -n "$id" ]; then
      task_tier=$(field tier)
      case "$task_tier" in
        trivial|standard|complex|deep) ;;
        *) echo "$id: tier '$task_tier' is not trivial, standard, complex or deep" >&2; exit 2;;
      esac
      IFS='|' read -r _ _ tier <<<"$(resolve_tier "$task_tier" "$cli")"
      case "$(field critical_zone)" in
        yes*) [ "$tier" = review-check ] && tier=review-validate;;
      esac
    else
      if [ "$kind" = design ]; then tier=review-deep; else tier=review-validate; fi
    fi;;
  trivial|standard|complex|deep)
    [ "$mode" = execute ] || { echo "execution tier '$model' is for execute, not review" >&2; exit 2; }
    tier=$model;;
  review-check|review-validate|review-deep)
    [ "$mode" = review ] || { echo "review tier '$model' is for review, not execute" >&2; exit 2; }
    tier=$model;;
esac
if [ -n "$tier" ]; then
  row=$(resolve_tier "$tier" "$cli")
  [ -n "$row" ] || { echo "tier '$tier' not found in $bot/models.md" >&2; exit 2; }
  IFS='|' read -r resolved_model resolved_effort _ <<<"$row"
  [ -n "$resolved_model" ] || { echo "no $cli model for tier '$tier' in $bot/models.md" >&2; exit 2; }
  model=$resolved_model
  [ -z "$effort" ] && effort=$resolved_effort
fi
reviewer="$roles/BASE.md and $roles/REVIEWER.md"
case "$mode" in
  execute)
    case "$state" in
      validated|rejected|abandoned|validada|rejeitada|abandonada) echo "$id is $state" >&2; exit 2;;
    esac
    case "$(field executor)" in
      dev) files="$roles/DEV.md";;
      tester) files="$roles/TESTER.md";;
      dev+tester) files="$roles/DEV.md and $roles/TESTER.md";;
      *) echo "$id: executor '$(field executor)' is not dev, tester or dev+tester" >&2; exit 2;;
    esac
    result="$root/.bot/tasks/$id-result.md"
    prompt="Read $files, then $task, and execute it. Answer with one status line."
    if [ -n "$gap" ]; then
      sent=$(grep -oE '^## Send-back [0-9]+' "$result" 2>/dev/null | grep -oE '[0-9]+$' | sort -n | tail -1)
      [ "${sent:-0}" -lt 5 ] || { echo "$id has had $sent send-backs, the limit: reject it" >&2; exit 2; }
      prompt="$prompt The TASK is sent back to you with this gap: $gap"
    fi;;
  review)
    if [ -n "$id" ]; then
      case "$state" in delivered|entregue) ;; *) echo "$id is $state, not delivered" >&2; exit 2;; esac
      result="$root/.bot/tasks/$id-review.md"
      prompt="Read $roles/REVIEWER.md, then, as a delegate, review the delivery of $task in the project $root. Answer with one status line."
    else
      [ -f "$roles/reviews/$kind.md" ] || { echo "no kind '$kind' in $roles/reviews/" >&2; exit 2; }
      result=""
      prompt="Read $reviewer and $roles/reviews/$kind.md, then, as a delegate, review by that kind in the project $root: $subject. Answer with one status line."
    fi;;
esac

case "$cli" in
  claude) cmd=(claude -p "$prompt" --model "$model" --permission-mode auto --output-format json
    --tools "Read,Edit,Write,Bash,Grep,Glob" --strict-mcp-config --disable-slash-commands);;
  agy) cmd=(agy -p "$prompt" --model "$model" --dangerously-skip-permissions
    --disable-slash-commands --output-format json
    --settings '{"agentMode":"","enableTerminalSandbox":false}' --add-dir "$roles");;
  *) echo "cli '$cli' is not claude or agy" >&2; exit 2;;
esac
[ -n "$effort" ] && cmd+=(--effort "$effort")
for d in ${dirs[@]+"${dirs[@]}"}; do cmd+=(--add-dir "$d"); done
if [ "$dry_run" -eq 1 ]; then
  echo "dry-run: $cli $model${effort:+ ($effort)}${tier:+ [$tier]}"
  exit 0
fi
command -v "$cli" >/dev/null || { echo "$cli not found in PATH" >&2; exit 2; }

lock="${TMPDIR:-/tmp}/bot-delegate-$(printf %s "$root" | md5sum | cut -c1-12).lock"
exec 9>"$lock"
flock -n 9 || { echo "another delegate is running on $root" >&2; exit 2; }

base=$(mktemp -d -p /tmp) && log="$base/delegate.log"
if [ "$cli" = agy ]; then
  # agy runs in bwrap: the filesystem read-only, except the project and each -w directory (not
  # their .git), agy's own state and $base/tmp as /tmp; of ~/Code, only those and the skill's
  # folder; secret
  # folders hidden; agy's summaries of past conversations replaced by empty files of this
  # run; the session bus only through a proxy that lets through the keyring, where agy keeps
  # its login; XDG_CACHE_HOME under /tmp, since ~/.cache is read-only there and nix writes its
  # caches in it
  for t in bwrap xdg-dbus-proxy; do command -v $t >/dev/null || { echo "$t not found in PATH" >&2; exit 2; }; done
  for v in XDG_RUNTIME_DIR DBUS_SESSION_BUS_ADDRESS; do [ -n "${!v:-}" ] || { echo "$v not set" >&2; exit 2; }; done
  mkdir "$base/tmp"
  agy_state=~/.gemini/antigravity-cli
  xdg-dbus-proxy "$DBUS_SESSION_BUS_ADDRESS" "$base/bus" --filter --talk=org.freedesktop.secrets & proxy=$!
  trap 'kill $proxy 2>/dev/null' EXIT
  for _ in $(seq 50); do [ -S "$base/bus" ] && break; sleep 0.1; done
  jail=(bwrap --ro-bind / / --dev /dev --proc /proc --bind "$base/tmp" /tmp
    --tmpfs ~/Code --ro-bind "$bot" "$bot" --bind "$root" "$root"
    --bind "$agy_state" "$agy_state"
    --tmpfs "$XDG_RUNTIME_DIR" --ro-bind "$base/bus" "$XDG_RUNTIME_DIR/bus"
    --setenv XDG_CACHE_HOME /tmp/cache)
  for f in conversation_summaries.db jetbox_summaries_proto.pb; do
    [ -e "$agy_state/$f" ] && : >"$base/$f" && jail+=(--bind "$base/$f" "$agy_state/$f")
  done
  for d in ${dirs[@]+"${dirs[@]}"}; do jail+=(--bind "$d" "$d"); done
  for p in "$root/.git" "$root/.bot/.git" ${dirs[@]+"${dirs[@]/%//.git}"}; do [ -e "$p" ] && jail+=(--ro-bind "$p" "$p"); done
  for p in ~/.ssh ~/.gnupg ~/.config/rclone ~/.config/gh ~/.local/share/keyrings ~/.claude; do
    [ -d "$p" ] && jail+=(--tmpfs "$p")
  done
  cmd=("${jail[@]}" --unshare-all --share-net --die-with-parent --chdir "$root" "${cmd[@]}")
  echo "the executor's /tmp: $base/tmp"
fi
touch "$base/start"
before=$(stat -c %Y "$result" 2>/dev/null || echo none)
start=$(date +%s) rc=0
out="$base/delegate.json"
(cd "$root" && timeout "${minutes}m" "${cmd[@]}" </dev/null >"$out" 2>"$log") || rc=$?
after=$(stat -c %Y "$result" 2>/dev/null || echo none)

echo "delegate: $cli $model${effort:+ ($effort)}${tier:+ [$tier]}, exit $rc, $(( $(date +%s) - start )) s"
if [ "$cli" = claude ] && jq -e .modelUsage "$out" >/dev/null 2>&1; then
  echo "status line: $(jq -r '.result // ""' "$out" | grep -v '^[[:space:]]*$' | tail -1)"
  jq -r '[.modelUsage[]] as $m
    | ($m | map(.inputTokens + .cacheCreationInputTokens + .cacheReadInputTokens) | add) as $in
    | ($m | map(.cacheReadInputTokens) | add) as $cached | ($m | map(.outputTokens) | add) as $o
    | (.total_cost_usd * 1000 | round / 1000) as $usd
    | "usage: \($in) tokens in, \($cached) from cache; \($o) out; \(.num_turns) turns; ~$\($usd) at API prices"' "$out"
  echo "log: $log, $out"
elif [ "$cli" = agy ] && jq -e .usage "$out" >/dev/null 2>&1; then
  echo "status line: $(jq -r '.response // ""' "$out" | grep -v '^[[:space:]]*$' | tail -1)"
  jq -r '"usage: \(.usage.input_tokens) tokens in, \(.usage.cache_read_tokens) from cache; \(.usage.output_tokens) out (\(.usage.thinking_tokens) thinking); \(.num_turns) turns"' "$out"
  echo "log: $log, $out"
else
  echo "status line: $(cat "$out" "$log" 2>/dev/null | grep -v '^[[:space:]]*$' | tail -1)"
  echo "log: $log, $out"
fi
if [ -n "$kind" ]; then
  reports=$(find "$root/.bot/reports" -mindepth 1 -maxdepth 1 -newer "$base/start" 2>/dev/null | sed "s|^$root/||")
  [ -n "$reports" ] || { echo "result: no new report"; exit 1; }
  echo "result: $reports"
  exit 0
fi
if [ "$after" = none ] || [ "$after" = "$before" ]; then
  echo "result: not written"
  exit 1
fi
case "$mode" in
  execute) echo "result: .bot/tasks/$id-result.md ($(sed -n -E 's/^status:[[:space:]]*//p' "$result" | head -1))";;
  review) echo "result: .bot/tasks/$id-review.md ($(sed -n -E 's/^suggested_verdict:[[:space:]]*//p' "$result" | head -1))";;
esac
