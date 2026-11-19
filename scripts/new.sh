#!/usr/bin/env bash
# usage: new.sh <root> campaign
#        new.sh <root> round CAMPAIGN-nnn
#        new.sh <root> task <dev|tester|dev+tester> [CAMPAIGN-nnn#N] [-r TASK-nnn]
#        new.sh <root> review TASK-nnn
# — creates in <root>/.bot/ the file a form of roles/templates/ shapes, at the next free number,
# with what is known filled: the number, the date, the project, the campaign and the round, the
# executor and its role files by absolute path, the reference. Every other <…> of the form is
# left for its writer. `campaign` creates its round-1.md too; a task outside a campaign has no
# campaign and round lines, and one with no -r no reference line. Never overwrites a file.
# Prints the path of each file created, relative to <root>.
set -eu
usage='usage: new.sh <root> campaign | round CAMPAIGN-nnn | task <dev|tester|dev+tester> [CAMPAIGN-nnn#N] [-r TASK-nnn] | review TASK-nnn'
[ $# -ge 2 ] || { echo "$usage" >&2; exit 2; }
root=$(cd "$1" && pwd); what=$2; shift 2
bot=$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)
dir="$root/.bot"
[ -d "$dir" ] || { echo "no $dir: create it first, with a git of its own" >&2; exit 2; }
today=$(date +%F) project=$(basename "$root")

form() { awk '/^````markdown$/ {on = 1; next} /^````$/ {on = 0} on' "$bot/roles/templates/$1"; }
next() { # next number of a prefix in a folder
  local n
  n=$(ls "$1" 2>/dev/null | grep -oE "^$2-[0-9]{3}" | sed "s/^$2-//" | sort -n | tail -1)
  printf '%s-%03d' "$2" $(( 10#${n:-0} + 1 ))
}
create() { # writes stdin to a new file, refusing one that exists
  mkdir -p "$(dirname "$1")"
  (set -C; cat > "$1") 2>/dev/null || { echo "${1#"$root"/} exists" >&2; exit 2; }
  echo "${1#"$root"/}"
}
campaign_id() { # CAMPAIGN-nnn or nnn → CAMPAIGN-nnn, its folder there
  local c=${1#CAMPAIGN-}
  [[ $c =~ ^[0-9]+$ ]] || { echo "$usage" >&2; exit 2; }
  c=CAMPAIGN-$(printf %03d $(( 10#$c )))
  [ -d "$dir/campaigns/$c" ] || { echo "no $dir/campaigns/$c/" >&2; exit 2; }
  echo "$c"
}
round() { # campaign, round number
  form ROUND.md | sed -E -e "s/CAMPAIGN-nnn/$1/g" -e "s/^round: N$/round: $2/" \
    -e "s/, round N —/, round $2 —/" -e "s/^created: YYYY-MM-DD$/created: $today/" |
    create "$dir/campaigns/$1/round-$2.md"
}

case "$what" in
  campaign)
    [ $# -eq 0 ] || { echo "$usage" >&2; exit 2; }
    c=$(next "$dir/campaigns" CAMPAIGN)
    mkdir -p "$dir/campaigns"
    mkdir "$dir/campaigns/$c" 2>/dev/null || { echo "$c exists" >&2; exit 2; }
    form CAMPAIGN.md | sed -E -e "s/CAMPAIGN-nnn/$c/g" -e "s/^project: <name>$/project: $project/" \
      -e "s/^created: YYYY-MM-DD$/created: $today/" | create "$dir/campaigns/$c/campaign.md"
    round "$c" 1;;
  round)
    [ $# -eq 1 ] || { echo "$usage" >&2; exit 2; }
    c=$(campaign_id "$1")
    n=$(ls "$dir/campaigns/$c" | sed -n -E 's/^round-([0-9]+)\.md$/\1/p' | sort -n | tail -1)
    round "$c" $(( ${n:-0} + 1 ));;
  task)
    ex=${1:-}; shift || true
    case "$ex" in
      dev) read_line="Read \`$bot/roles/DEV.md\`";;
      tester) read_line="Read \`$bot/roles/TESTER.md\`";;
      dev+tester) read_line="Read \`$bot/roles/DEV.md\` and \`$bot/roles/TESTER.md\`";;
      *) echo "$usage" >&2; exit 2;;
    esac
    c="" n="" ref=""
    while [ $# -gt 0 ]; do
      case "$1" in
        -r) ref=TASK-${2#TASK-}; [ -f "$dir/tasks/$ref.md" ] || { echo "no $dir/tasks/$ref.md" >&2; exit 2; }; shift 2;;
        *#*) c=$(campaign_id "${1%%#*}"); n=${1##*#}
          [ -f "$dir/campaigns/$c/round-$n.md" ] || { echo "no $dir/campaigns/$c/round-$n.md" >&2; exit 2; }
          shift;;
        *) echo "$usage" >&2; exit 2;;
      esac
    done
    t=$(next "$dir/tasks" TASK)
    edits=(-e "s/TASK-nnn/$t/g" -e "s/^project: <name>$/project: $project/"
      -e "s/^created: YYYY-MM-DD$/created: $today/" -e "s/^executor: .*/executor: $ex/"
      -e "s|^Read \`<bot>/roles/DEV.md\` \[and \`<bot>/roles/TESTER.md\`\]$|$read_line|")
    if [ -n "$c" ]; then edits+=(-e "s/^campaign: <.*/campaign: $c/" -e "s/^round: <.*/round: $n/")
    else edits+=(-e '/^campaign: </d' -e '/^round: </d'); fi
    if [ -n "$ref" ]; then edits+=(-e "s/^reference: <.*/reference: $ref/")
    else edits+=(-e '/^reference: </d'); fi
    form TASK.md | sed -E "${edits[@]}" | create "$dir/tasks/$t.md";;
  review)
    [ $# -eq 1 ] || { echo "$usage" >&2; exit 2; }
    t=TASK-${1#TASK-}
    [ -f "$dir/tasks/$t.md" ] || { echo "no $dir/tasks/$t.md" >&2; exit 2; }
    form TASK-REVIEW.md | sed -E -e "s/TASK-nnn/$t/g" -e "s/^date: YYYY-MM-DD$/date: $today/" |
      create "$dir/tasks/$t-review.md";;
  *) echo "$usage" >&2; exit 2;;
esac
