#!/usr/bin/env bash
# usage: boot.sh <root> — prints the facts of /bot's boot line for a project
set -eu
root=$(cd "${1:?usage: boot.sh <root>}" && pwd)
bot="$root/.bot"

echo "root: $root"
if git -C "$root" rev-parse --git-dir >/dev/null 2>&1; then
  echo "git: $(git -C "$root" branch --show-current) @ $(git -C "$root" rev-parse --short HEAD), $(git -C "$root" status --porcelain | wc -l) changed"
fi
[ -d "$root/.tasks" ] && echo "legacy: .tasks/ exists, waits to be moved to .bot/tasks/"
if [ ! -d "$bot" ]; then
  echo "bot: none; next TASK-001, CAMPAIGN-001"
  exit 0
fi

next() { # next number of a prefix in a folder
  local n
  n=$(ls "$1" 2>/dev/null | grep -oE "^$2-[0-9]{3}" | sed "s/^$2-//" | sort -n | tail -1)
  printf '%s-%03d' "$2" $(( 10#${n:-0} + 1 ))
}
state() { sed -n -E 's/^(state|estado):[[:space:]]*//p' "$1" | head -1; }

open_tasks=() delivered=()
for f in "$bot"/tasks/TASK-[0-9][0-9][0-9].md; do
  [ -e "$f" ] || continue
  id=$(basename "$f" .md); s=$(state "$f")
  case "$s" in validated|rejected|validada|rejeitada|abandonada|abandoned) ;; *) open_tasks+=("$id ($s)");; esac
  case "$s" in delivered|entregue)
    [ -e "$bot/tasks/$id-review.md" ] || [ -e "$bot/tasks/$id-revisao.md" ] || delivered+=("$id");;
  esac
done
open_camps=()
for f in "$bot"/campaigns/CAMPAIGN-[0-9][0-9][0-9].md "$bot"/campaigns/CAMPAIGN-[0-9][0-9][0-9]/campaign.md; do
  [ -e "$f" ] || continue
  s=$(state "$f")
  case "$s" in draft|confirmed) ;; *) continue;; esac
  if [ "$(basename "$f")" = campaign.md ]; then
    d=$(dirname "$f"); r=""
    for rf in "$d"/round-*.md; do
      [ -e "$rf" ] || continue
      rs=$(state "$rf")
      case "$rs" in draft|confirmed) r=", $(basename "$rf" .md) $rs";; esac
    done
    open_camps+=("$(basename "$d") ($s$r)")
  else
    open_camps+=("$(basename "$f" .md) ($s)")
  fi
done

echo "open TASKs: ${open_tasks[*]:-none}"
echo "delivered without review: ${delivered[*]:-none}"
echo "open campaigns: ${open_camps[*]:-none}"
echo "next: $(next "$bot/tasks" TASK), $(next "$bot/campaigns" CAMPAIGN)"
last_report=$(ls "$bot/reports" 2>/dev/null | sort | tail -1)
echo "last report: ${last_report:-none}"
if [ -f "$bot/knowledge/INDEX.md" ]; then
  ib=$(wc -c < "$bot/knowledge/INDEX.md")
  echo "knowledge: $(grep -c '^- \[' "$bot/knowledge/INDEX.md") facts, index $ib B$([ "$ib" -gt 3072 ] && echo ' — over 3 KB: run /bot learn --merge')"
fi
logs=()
for f in "$bot"/campaigns/CAMPAIGN-[0-9][0-9][0-9].md "$bot"/campaigns/CAMPAIGN-[0-9][0-9][0-9]/round-*.md "$bot"/campaigns/AUTO-*.md; do [ -e "$f" ] && logs+=("$f"); done
if [ ${#logs[@]} -gt 0 ]; then
  awk '
    /^#+ / { inb = ($0 ~ /^#+ Blocks[[:space:]]*$/) }
    inb && /^- \[ \]/ { open++; last = FILENAME ":" FNR; pend[last] = 1 }
    inb && /^[[:space:]]+Answer:[[:space:]]*[^[:space:]]/ && last != "" { if (pend[last]) { ans++; pend[last] = 0 } }
    END { if (open) printf "blocks: %d waiting, %d answered in the file\n", open - ans, ans }' "${logs[@]}"
fi
if git -C "$bot" rev-parse --git-dir >/dev/null 2>&1; then
  learn=$(git -C "$bot" log --grep='^learn' --format='%h %ad' --date=short -1 2>/dev/null || true)
  echo "last harvest: ${learn:-none}; .bot uncommitted: $(git -C "$bot" status --porcelain | wc -l)"
fi
