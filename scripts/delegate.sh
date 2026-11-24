#!/usr/bin/env bash
# usage: delegate.sh <root> [review | reader] <TASK-nnn | --<kind> <subject> | <folder>> <claude|agy> <model|tier|auto>
# [-e <effort>] [-g <gap>] [-t <minutes>] [-w <dir>]... [-n] — runs a TASK's executor, a REVIEWER,
# or a READER in claude or agy, headless, from the project's root. Without `review` or `reader`:
# executes the TASK (-g sends it back with that gap, refused once its result holds `## Send-back 5`).
# With `review`: reviews the delivery of a TASK in state delivered, or reviews by a kind of
# roles/reviews/ on a subject. With `reader`: extracts conversation lessons from <folder> into
# <folder>/candidates.json (-g redoes it with lessons.jq's errors). <model|tier|auto> accepts a
# literal model ID, a tier name of models.md
# (or READER), or `auto` (reads `tier:` / `critical_zone:` from the TASK, derives from --<kind>, or
# resolves READER). -e sets or overrides reasoning effort (low|medium|high|xhigh|max). -n resolves
# and validates without running. Prints the delegate's status line, what it wrote, the log paths,
# and the session's tokens and turns; appends one JSONL telemetry record to
# <root>/.bot/delegations.jsonl (or $BOT_TELEMETRY_LOG); exits 1 when it wrote nothing. claude runs
# with the tools of a role's work alone (no web, MCP, skills or background tasks); agy runs with
# slash commands disabled and JSON output. -w gives the delegate a directory outside the project to
# work in, its .git read-only under agy.
set -eu
usage="usage: delegate.sh <root> [review | reader] <TASK-nnn | --<kind> <subject> | <folder>> <claude|agy> <model|tier|auto> [-e <effort>] [-g <gap>] [-t <minutes>] [-w <dir>]... [-n]"
root=$(cd "${1:?$usage}" && pwd); shift
bot=$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)
roles="$bot/roles"
mode=execute id="" kind="" subject="" folder=""
case "${1:-}" in
  review) mode=review; shift;;
  reader) mode=reader; shift;;
esac
if [ "$mode" = reader ]; then
  [ -d "${1:?$usage}" ] || { echo "no directory ${1:-}" >&2; exit 2; }
  folder=$(cd "$1" && pwd); shift
else
  case "${1:?$usage}" in
    --*) [ $mode = review ] || { echo "$usage" >&2; exit 2; }; kind=${1#--} subject=${2:?$usage}; shift 2;;
    *) id=$1; shift;;
  esac
fi
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
[ -z "$gap" ] || [ $mode != review ] || { echo "-g is for an execution or a reader, not a review" >&2; exit 2; }
case "$cli" in claude|agy) ;; *) echo "cli '$cli' is not claude or agy" >&2; exit 2;; esac

if [ -n "$id" ]; then
  id=TASK-${id#TASK-}
  task="$root/.bot/tasks/$id.md"
  [ -f "$task" ] || { echo "no $task" >&2; exit 2; }
  field() { awk '/^---$/{n++; if(n==2) exit; next} n==1' "$task" | sed -n -E "s/^$1:[[:space:]]*//p" | head -1; }
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
      if (NF >= 7) {
        r = $6; gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", r)
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
    if [ "$mode" = reader ]; then
      tier=READER
    elif [ "$mode" = execute ]; then
      tier=$(field tier)
      case "$tier" in
        standard|complex|deep) ;;
        *) echo "$id: tier '$tier' is not standard, complex or deep" >&2; exit 2;;
      esac
    elif [ -n "$id" ]; then
      task_tier=$(field tier)
      case "$task_tier" in
        standard|complex|deep) ;;
        *) echo "$id: tier '$task_tier' is not standard, complex or deep" >&2; exit 2;;
      esac
      IFS='|' read -r _ _ tier <<<"$(resolve_tier "$task_tier" "$cli")"
      case "$(field critical_zone)" in
        yes*) [ "$tier" = review-check ] && tier=review-validate;;
      esac
    else
      if [ "$kind" = design ]; then tier=review-deep; else tier=review-validate; fi
    fi;;
  standard|complex|deep)
    [ "$mode" = execute ] || { echo "execution tier '$model' is for execute, not $mode" >&2; exit 2; }
    tier=$model;;
  review-check|review-validate|review-deep)
    [ "$mode" = review ] || { echo "review tier '$model' is for review, not $mode" >&2; exit 2; }
    tier=$model;;
  reader|READER)
    [ "$mode" = reader ] || { echo "role tier '$model' is for reader, not $mode" >&2; exit 2; }
    tier=READER;;
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
send_back="null"
target=""
case "$mode" in
  execute)
    target="$id"
    send_back=0
    case "$state" in
      validated|rejected|abandoned|validada|rejeitada|abandonada) echo "$id is $state" >&2; exit 2;;
    esac
    case "$(field executor)" in
      dev) files="$roles/DEV.md";;
      tester) files="$roles/TESTER.md";;
      dev+tester) files="$roles/DEV.md and $roles/TESTER.md";;
      writer) files="$roles/WRITER.md";;
      *) echo "$id: executor '$(field executor)' is not dev, tester, dev+tester or writer" >&2; exit 2;;
    esac
    result="$root/.bot/tasks/$id-result.md"
    prompt="Read $files, then $task, and execute it. Answer with one status line."
    if [ -n "$gap" ]; then
      sent=$(grep -oE '^## Send-back [0-9]+' "$result" 2>/dev/null | grep -oE '[0-9]+$' | sort -n | tail -1)
      [ "${sent:-0}" -lt 5 ] || { echo "$id has had $sent send-backs, the limit: reject it" >&2; exit 2; }
      send_back=$(( ${sent:-0} + 1 ))
      prompt="$prompt The TASK is sent back to you with this gap (quote it verbatim as 'Gap: ...' at the top of '## Send-back $send_back'): $gap"
    fi;;
  review)
    if [ -n "$id" ]; then
      target="$id"
      case "$state" in delivered|entregue) ;; *) echo "$id is $state, not delivered" >&2; exit 2;; esac
      result="$root/.bot/tasks/$id-review.md"
      prompt="Read $roles/REVIEWER.md, then, as a delegate, review the delivery of $task in the project $root. Answer with one status line."
    else
      target="--$kind $subject"
      [ -f "$roles/reviews/$kind.md" ] || { echo "no kind '$kind' in $roles/reviews/" >&2; exit 2; }
      result=""
      prompt="Read $reviewer and $roles/reviews/$kind.md, then, as a delegate, review by that kind in the project $root: $subject. Answer with one status line."
    fi;;
  reader)
    target="$folder"
    result="$folder/candidates.json"
    prompt="Read $roles/READER.md, $root/.bot/knowledge/INDEX.md and all .txt extracts in $folder, and write the answer to $folder/candidates.json. Follow READER.md strictly and answer with one status line."
    [ -z "$gap" ] || prompt="$prompt Your previous candidates.json failed lessons.jq with these errors; rewrite it to fix them: $gap";;
esac

case "$cli" in
  claude) cmd=(claude -p "$prompt" --model "$model" --permission-mode auto --output-format json
    --tools "Read,Edit,Write,Bash,Grep,Glob" --strict-mcp-config --disable-slash-commands)
    [ "$mode" = reader ] && cmd+=(--add-dir "$folder" --add-dir "$roles");;
  agy) cmd=(agy -p "$prompt" --model "$model" --dangerously-skip-permissions
    --disable-slash-commands --output-format json
    --settings '{"agentMode":"","enableTerminalSandbox":false}' --add-dir "$roles")
    [ "$mode" = reader ] && cmd+=(--add-dir "$folder");;
  *) echo "cli '$cli' is not claude or agy" >&2; exit 2;;
esac
[ -n "$effort" ] && cmd+=(--effort "$effort")
for d in ${dirs[@]+"${dirs[@]}"}; do cmd+=(--add-dir "$d"); done
if [ "$dry_run" -eq 1 ]; then
  echo "dry-run: $cli $model${effort:+ ($effort)}${tier:+ [$tier]} ($mode: $target)"
  exit 0
fi
command -v "$cli" >/dev/null || { echo "$cli not found in PATH" >&2; exit 2; }

lock="${TMPDIR:-/tmp}/bot-delegate-$(printf %s "$root" | md5sum | cut -c1-12).lock"
exec 9>"$lock"
flock -n 9 || { echo "another delegate is running on $root" >&2; exit 2; }

base=$(mktemp -d -p /tmp) && log="$base/delegate.log"
if [ "$cli" = agy ]; then
  # agy runs in bwrap: the filesystem read-only, except the project (read-only for reader) and
  # each -w directory (not their .git), an ephemeral tmpfs for agy's state (only builtin,
  # installation_id and settings.json bound read-only, and bin writable, where agy rewrites its
  # agentapi script on each command — no past summaries, no host WAL sidecar corruption) and
  # $base/tmp as /tmp (with $folder bound writable afterwards for reader); of ~/Code (when
  # present), only those, the skill's folder, and the real directory of GEMINI.md (read-only, so a
  # symlinked global rule and its includes stay readable); secret folders hidden; skills, plugins
  # and mcp_config.json masked read-only empty so delegates carry no ambient skills/MCPs; the
  # session bus only through a proxy that lets through the keyring, where agy keeps its login;
  # XDG_CACHE_HOME under /tmp, since ~/.cache is read-only there and nix writes its caches in it.
  for t in bwrap xdg-dbus-proxy; do command -v $t >/dev/null || { echo "$t not found in PATH" >&2; exit 2; }; done
  for v in XDG_RUNTIME_DIR DBUS_SESSION_BUS_ADDRESS; do [ -n "${!v:-}" ] || { echo "$v not set" >&2; exit 2; }; done
  mkdir "$base/tmp" "$base/empty"
  agy_state=~/.gemini/antigravity-cli
  rules_file=$(readlink -f ~/.gemini/config/GEMINI.md 2>/dev/null || true)
  rules_dir=""; [ -f "$rules_file" ] && rules_dir=$(dirname "$rules_file")
  xdg-dbus-proxy "$DBUS_SESSION_BUS_ADDRESS" "$base/bus" --filter --talk=org.freedesktop.secrets & proxy=$!
  trap 'kill $proxy 2>/dev/null' EXIT
  for _ in $(seq 50); do [ -S "$base/bus" ] && break; sleep 0.1; done
  jail=(bwrap --ro-bind / / --dev /dev --proc /proc --bind "$base/tmp" /tmp)
  [ -d ~/Code ] && jail+=(--tmpfs ~/Code)
  if [ -n "$rules_dir" ]; then
    case "$rules_dir/" in "$root"/*) ;; *) jail+=(--ro-bind "$rules_dir" "$rules_dir");; esac
  fi
  if [ "$mode" = reader ]; then
    jail+=(--ro-bind "$bot" "$bot" --ro-bind "$root" "$root" --bind "$folder" "$folder")
  else
    jail+=(--ro-bind "$bot" "$bot" --bind "$root" "$root")
  fi
  jail+=(--tmpfs "$agy_state"
    --tmpfs "$XDG_RUNTIME_DIR" --ro-bind "$base/bus" "$XDG_RUNTIME_DIR/bus"
    --setenv XDG_CACHE_HOME /tmp/cache)
  for p in builtin installation_id settings.json; do
    [ -e "$agy_state/$p" ] && jail+=(--ro-bind "$agy_state/$p" "$agy_state/$p")
  done
  [ -e "$agy_state/bin" ] && jail+=(--bind "$agy_state/bin" "$agy_state/bin")
  for d in ~/.gemini/config/skills ~/.gemini/config/plugins "$agy_state/builtin/skills" "$agy_state/builtin/plugins"; do
    [ -d "$d" ] && jail+=(--ro-bind "$base/empty" "$d")
  done
  if [ -e ~/.gemini/config/mcp_config.json ]; then
    printf '{}' >"$base/mcp_config.json"
    jail+=(--ro-bind "$base/mcp_config.json" ~/.gemini/config/mcp_config.json)
  fi
  for d in ${dirs[@]+"${dirs[@]}"}; do jail+=(--bind "$d" "$d"); done
  if [ "$mode" != reader ]; then
    for p in "$root/.git" "$root/.bot/.git" ${dirs[@]+"${dirs[@]/%//.git}"}; do [ -e "$p" ] && jail+=(--ro-bind "$p" "$p"); done
  fi
  for p in ~/.ssh ~/.gnupg ~/.config/rclone ~/.config/gh ~/.local/share/keyrings ~/.claude; do
    [ -d "$p" ] && jail+=(--tmpfs "$p")
  done
  cmd=("${jail[@]}" --unshare-all --share-net --die-with-parent --chdir "$root" "${cmd[@]}")
  echo "the executor's /tmp: $base/tmp"
fi
touch "$base/start"
before=$(stat -c '%Y %s' "$result" 2>/dev/null || echo none)
start=$(date +%s) rc=0
out="$base/delegate.json"
(cd "$root" && timeout "${minutes}m" "${cmd[@]}" </dev/null >"$out" 2>"$log") || rc=$?
after=$(stat -c '%Y %s' "$result" 2>/dev/null || echo none)
duration=$(( $(date +%s) - start ))
ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)

in_new=null in_cached=null out_tok=null think_tok=null turns=null cost_usd=null
echo "delegate: $cli $model${effort:+ ($effort)}${tier:+ [$tier]}, exit $rc, $duration s"
if [ "$cli" = claude ] && jq -e .modelUsage "$out" >/dev/null 2>&1; then
  echo "status line: $(jq -r '.result // ""' "$out" | grep -v '^[[:space:]]*$' | tail -1)"
  IFS=' ' read -r in_new in_cached out_tok turns cost_usd <<<"$(jq -r '[.modelUsage[]] as $m
    | ($m | map((.inputTokens // 0) + (.cacheCreationInputTokens // 0)) | add // 0) as $new
    | ($m | map(.cacheReadInputTokens // 0) | add // 0) as $cached
    | ($m | map(.outputTokens // 0) | add // 0) as $o
    | ((.total_cost_usd // 0) * 1000 | round / 1000) as $usd
    | "\($new) \($cached) \($o) \(.num_turns // "null") \($usd)"' "$out")"
  echo "usage: $((in_new + in_cached)) tokens in ($in_new new, $in_cached from cache); $out_tok out; $turns turns; ~\$$cost_usd at API prices"
  echo "log: $log, $out"
elif [ "$cli" = agy ] && jq -e .usage "$out" >/dev/null 2>&1; then
  echo "status line: $(jq -r '.response // ""' "$out" | grep -v '^[[:space:]]*$' | tail -1)"
  IFS=' ' read -r in_new in_cached out_tok think_tok turns <<<"$(jq -r '(.usage.input_tokens // 0) as $new
    | (.usage.cache_read_tokens // 0) as $cached
    | (.usage.output_tokens // 0) as $o
    | (.usage.thinking_tokens // 0) as $th
    | "\($new) \($cached) \($o) \($th) \(.num_turns // "null")"' "$out")"
  echo "usage: $((in_new + in_cached)) tokens in ($in_new new, $in_cached from cache); $out_tok out ($think_tok thinking); $turns turns"
  echo "log: $log, $out"
else
  echo "status line: $(cat "$out" "$log" 2>/dev/null | grep -v '^[[:space:]]*$' | tail -1)"
  echo "log: $log, $out"
fi

res_state="not_written" exit_code=0
if [ -n "$kind" ]; then
  reports=$(find "$root/.bot/reports" -mindepth 1 -maxdepth 1 -newer "$base/start" 2>/dev/null | sed "s|^$root/||")
  if [ -n "$reports" ]; then
    res_state="$reports"
    echo "result: $reports"
  else
    echo "result: no new report"
    exit_code=1
  fi
elif [ "$after" = none ] || [ "$after" = "$before" ]; then
  echo "result: not written"
  exit_code=1
else
  case "$mode" in
    execute)
      res_state=$(sed -n -E 's/^status:[[:space:]]*//p' "$result" | head -1)
      echo "result: .bot/tasks/$id-result.md ($res_state)";;
    review)
      res_state=$(sed -n -E 's/^suggested_verdict:[[:space:]]*//p' "$result" | head -1)
      echo "result: .bot/tasks/$id-review.md ($res_state)";;
    reader)
      cnt=$(jq 'length' "$result" 2>/dev/null || echo invalid)
      res_state="${cnt}_candidates"
      echo "result: $result ($cnt candidates)";;
  esac
fi

telemetry="${BOT_TELEMETRY_LOG:-$root/.bot/delegations.jsonl}"
if [ -n "${BOT_TELEMETRY_LOG:-}" ] || [ -d "$root/.bot" ]; then
  jq -nc \
    --arg ts "$ts" \
    --arg project "$(basename "$root")" \
    --arg mode "$mode" \
    --arg target "$target" \
    --argjson send_back "$send_back" \
    --arg cli "$cli" \
    --arg tier "$tier" \
    --arg model "$model" \
    --arg effort "$effort" \
    --argjson exit "$rc" \
    --argjson duration_s "$duration" \
    --argjson turns "$turns" \
    --argjson input_new "$in_new" \
    --argjson input_cached "$in_cached" \
    --argjson output "$out_tok" \
    --argjson thinking "$think_tok" \
    --argjson cost_usd "$cost_usd" \
    --arg result "$res_state" \
    '{ts:$ts, project:$project, mode:$mode, target:$target, send_back:$send_back, cli:$cli,
      tier:(if $tier == "" then null else $tier end), model:$model,
      effort:(if $effort == "" then null else $effort end), exit:$exit, duration_s:$duration_s,
      turns:$turns, input_new:$input_new, input_cached:$input_cached, output:$output,
      thinking:$thinking, cost_usd:$cost_usd, result:$result}' >>"$telemetry"
fi
exit "$exit_code"
