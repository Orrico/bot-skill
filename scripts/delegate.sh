#!/usr/bin/env bash
# usage: delegate.sh <root> [review] <TASK-nnn | --<kind> <subject>> <claude|agy> <model> [-g <gap>]
# [-t <minutes>] — runs a TASK's executor, or a REVIEWER, in another CLI, headless, from the
# project's root. Without `review`: executes the TASK (-g sends it back with that gap). With
# `review`: reviews the delivery of a TASK in state delivered, or reviews by a kind of
# roles/reviews/ on a subject. Prints the delegate's status line, what it wrote and the log's
# path; exits 1 when it wrote nothing
set -eu
usage="usage: delegate.sh <root> [review] <TASK-nnn | --<kind> <subject>> <claude|agy> <model> [-g <gap>] [-t <minutes>]"
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
gap="" minutes=60
while [ $# -gt 0 ]; do
  case "$1" in -g) gap=$2; shift 2;; -t) minutes=$2; shift 2;; *) echo "$usage" >&2; exit 2;; esac
done
[ -z "$gap" ] || [ $mode = execute ] || { echo "-g is for an execution, not a review" >&2; exit 2; }

if [ -n "$id" ]; then
  task="$root/.bot/tasks/$id.md"
  [ -f "$task" ] || { echo "no $task" >&2; exit 2; }
  field() { sed -n -E "s/^$1:[[:space:]]*//p" "$task" | head -1; }
  state="$(field state)$(field estado)"
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
    [ -z "$gap" ] || prompt="$prompt The TASK is sent back to you with this gap: $gap";;
  review)
    if [ -n "$id" ]; then
      case "$state" in delivered|entregue) ;; *) echo "$id is $state, not delivered" >&2; exit 2;; esac
      result="$root/.bot/tasks/$id-review.md"
      prompt="Read $reviewer, then, as a delegate, review the delivery of $task in the project $root. Answer with one status line."
    else
      [ -f "$roles/reviews/$kind.md" ] || { echo "no kind '$kind' in $roles/reviews/" >&2; exit 2; }
      result=""
      prompt="Read $reviewer and $roles/reviews/$kind.md, then, as a delegate, review by that kind in the project $root: $subject. Answer with one status line."
    fi;;
esac

case "$cli" in
  claude) cmd=(claude -p "$prompt" --model "$model" --permission-mode auto);;
  agy) cmd=(agy -p "$prompt" --model "$model" --dangerously-skip-permissions --add-dir "$roles");;
  *) echo "cli '$cli' is not claude or agy" >&2; exit 2;;
esac
command -v "$cli" >/dev/null || { echo "$cli not found in PATH" >&2; exit 2; }

lock="${TMPDIR:-/tmp}/bot-delegate-$(printf %s "$root" | md5sum | cut -c1-12).lock"
exec 9>"$lock"
flock -n 9 || { echo "another delegate is running on $root" >&2; exit 2; }

base=$(mktemp -d -p /tmp) && log="$base/delegate.log"
if [ "$cli" = agy ]; then
  # agy runs in bwrap: the filesystem read-only, except the project (not its .git), agy's own
  # state and $base/tmp as /tmp; of ~/Code, only the project and the skill's folder; secret
  # folders hidden; agy's summaries of past conversations replaced by empty files of this
  # run; the session bus only through a proxy that lets through the keyring, where agy keeps
  # its login
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
    --tmpfs "$XDG_RUNTIME_DIR" --ro-bind "$base/bus" "$XDG_RUNTIME_DIR/bus")
  for f in conversation_summaries.db jetbox_summaries_proto.pb; do
    [ -e "$agy_state/$f" ] && : >"$base/$f" && jail+=(--bind "$base/$f" "$agy_state/$f")
  done
  for p in "$root/.git" "$root/.bot/.git"; do [ -e "$p" ] && jail+=(--ro-bind "$p" "$p"); done
  for p in ~/.ssh ~/.gnupg ~/.config/rclone ~/.config/gh ~/.local/share/keyrings ~/.claude; do
    [ -d "$p" ] && jail+=(--tmpfs "$p")
  done
  cmd=("${jail[@]}" --unshare-all --share-net --die-with-parent --chdir "$root" "${cmd[@]}")
  echo "the executor's /tmp: $base/tmp"
fi
touch "$base/start"
before=$(stat -c %Y "$result" 2>/dev/null || echo none)
start=$(date +%s) rc=0
(cd "$root" && timeout "${minutes}m" "${cmd[@]}" </dev/null >"$log" 2>&1) || rc=$?
after=$(stat -c %Y "$result" 2>/dev/null || echo none)

echo "delegate: $cli $model, exit $rc, $(( $(date +%s) - start )) s"
echo "status line: $(grep -v '^[[:space:]]*$' "$log" | tail -1)"
echo "log: $log"
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
