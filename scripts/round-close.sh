#!/usr/bin/env bash
# usage: round-close.sh <root> CAMPAIGN-nnn#N — checks a round's file before it is closed:
#   rows       each row of "Plan" is done, blocked or dropped; a done row's last TASK is
#              validated and each commit after a `→` in its TASK cell is in git
#   send-backs each TASK of the plan has at most 5 (`## Send-back N` in its result); 3 to 5
#              print a note, since past 2 needs the user's authorization
#   report     "Checks" has a command with its output (`→`); "Not done" has a line for each
#              row blocked or dropped; each line of "Send-backs and re-issues" has a cause of
#              the set in roles/templates/ROUND.md, and each TASK sent back has a line there
#   reviews    a validated TASK with no review file prints a note
# Prints `problem:` and `note:` lines, then a summary; exits 1 when there is a problem.
set -u
usage='usage: round-close.sh <root> CAMPAIGN-nnn#N'
[ $# -eq 2 ] || { echo "$usage" >&2; exit 2; }
root=$(cd "$1" && pwd) || exit 2
case "$2" in *#*) ;; *) echo "$usage" >&2; exit 2;; esac
c=${2%%#*} n=${2##*#}
c=${c#CAMPAIGN-}
[[ $c =~ ^[0-9]+$ && $n =~ ^[0-9]+$ ]] || { echo "$usage" >&2; exit 2; }
campaign=CAMPAIGN-$(printf %03d "$((10#$c))")
round="$root/.bot/campaigns/$campaign/round-$n.md"
[ -f "$round" ] || { echo "no $round" >&2; exit 2; }
tasks="$root/.bot/tasks"
here=$(cd "$(dirname "$(readlink -f "$0")")" && pwd)
causes=$(sed -n -E 's/^\| `([a-z]+)` \|.*/\1/p' "$here/../roles/templates/ROUND.md" | paste -sd'|')
[ -n "$causes" ] || { echo "no causes in roles/templates/ROUND.md" >&2; exit 2; }

problems=0
problem() { echo "problem: $*"; problems=$((problems + 1)); }
note() { echo "note: $*"; }
field() { awk '/^---$/{n++; if(n==2) exit; next} n==1' "$1" | sed -n -E "s/^($2):[[:space:]]*//p" | head -1; }
section() { awk -v h="### $1" '$0 == h {on = 1; next} /^##/ {on = 0} on' "$round"; }
sendbacks() { grep -oE '^## Send-back [0-9]+' "$1" 2>/dev/null | grep -oE '[0-9]+$' | sort -n | tail -1; }

# the plan's rows as "number<TAB>TASK cell<TAB>state", by the columns its header names
rows=$(awk -F'|' '
  /^\| *# *\|/ { for (i = 2; i < NF; i++) { c = $i; gsub(/^ +| +$/, "", c); col[c] = i }; on = 1; next }
  on && /^\| *[0-9]+ *\|/ {
    if (!("TASK" in col) || !("State" in col)) { print "MISSING_COLS"; exit }
    t = $col["TASK"]; s = $col["State"]; k = $2
    gsub(/^ +| +$/, "", t); gsub(/^ +| +$/, "", s); gsub(/ /, "", k)
    print k "\t" t "\t" s; next }
  on && !/^\|/ { on = 0 }' "$round")
if [ "$rows" = MISSING_COLS ]; then
  problem "plan table header must have 'TASK' and 'State' columns"
  rows=""
elif [ -z "$rows" ]; then
  problem "no row in the plan"
fi

closed=0
while IFS=$'\t' read -r item cell state; do
  [ -n "$item" ] || continue
  case "$state" in
    done) ;;
    blocked|dropped) closed=$((closed + 1)); continue;;
    *) problem "#$item is '$state', not done, blocked or dropped"; continue;;
  esac
  last=$(grep -oE 'TASK-[0-9]{3}' <<<"$cell" | tail -1)
  if [ -n "$last" ]; then
    if [ -f "$tasks/$last.md" ]; then
      s=$(field "$tasks/$last.md" 'state|estado')
      case "$s" in validated|validada) ;; *) problem "#$item is done, its last TASK $last is '$s'";; esac
    else
      problem "#$item: no $last.md"
    fi
  fi
  for h in $(grep -oE '→ *`?[0-9a-f]{7,40}' <<<"$cell" | grep -oE '[0-9a-f]{7,40}'); do
    git -C "$root" cat-file -e "$h^{commit}" 2>/dev/null || problem "#$item: commit $h is not in git"
  done
done <<<"$rows"

for t in $(cut -f2 <<<"$rows" | grep -oE 'TASK-[0-9]{3}' | sort -u); do
  k=$(sendbacks "$tasks/$t-result.md")
  if [ -n "$k" ] && [ "$k" -gt 5 ]; then problem "$t has $k send-backs, past the limit of 5"
  elif [ -n "$k" ] && [ "$k" -gt 2 ]; then note "$t has $k send-backs, past 2: the user's authorization"
  fi
  [ -n "$k" ] && ! section 'Send-backs and re-issues' | grep -q "$t" &&
    problem "$t was sent back, and has no line in \"Send-backs and re-issues\""
  case "$(field "$tasks/$t.md" 'state|estado' 2>/dev/null)" in validated|validada) v=1;; *) v=0;; esac
  if [ $v = 1 ] &&
     [ ! -f "$tasks/$t-review.md" ] && [ ! -f "$tasks/$t-revisao.md" ]; then
    note "$t is validated with no review file"
  fi
done

checks=$(section Checks)
grep -q '→' <<<"$checks" || problem "\"Checks\" has no command with its output (→)"
if [ "$closed" -gt 0 ]; then
  lines=$(section 'Not done' | grep -E '^- ' | grep -viE '^- *(none|nenhum|nenhuma)\.?$' | wc -l)
  [ "$lines" -ge "$closed" ] || problem "\"Not done\" has $lines lines for $closed rows blocked or dropped"
fi
while IFS= read -r l; do
  grep -qE "^- *TASK-[0-9]{3} — \`?($causes)\`? — " <<<"$l" ||
    problem "a send-back's line has no cause of the set ($causes): ${l:0:100}"
done < <(section 'Send-backs and re-issues' | grep -E '^- ' | grep -viE '^- *(none|nenhum|nenhuma)\.?$')

if [ "$problems" -eq 0 ]; then echo "ok: $campaign round $n"; else echo "$problems problems: $campaign round $n"; exit 1; fi
