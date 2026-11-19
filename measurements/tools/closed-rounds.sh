#!/usr/bin/env bash
# usage: closed-rounds.sh <root> — runs scripts/round-close.sh on every round of the project in
# state closed, and counts its problem and note lines by kind. Reads only.
set -u
root=$(cd "${1:?usage: closed-rounds.sh <root>}" && pwd)
bot=$(cd "$(dirname "$(readlink -f "$0")")/../.." && pwd)
n=0
for r in "$root"/.bot/campaigns/CAMPAIGN-*/round-*.md; do
  grep -qE '^state: closed' "$r" || continue
  c=$(basename "$(dirname "$r")"); k=${r##*/round-}; k=${k%.md}
  n=$((n + 1)); "$bot/scripts/round-close.sh" "$root" "$c#$k"
done | sed -n -E 's/^(problem|note): (#[0-9]+ is .*|TASK-[0-9]+ )?.*(not done, blocked or dropped|its last TASK|is not in git|past the limit|past 2|no line in|no cause of the set|no command with its output|"Not done" has|with no review file).*/\1: \3/p' |
  sort | uniq -c | sort -rn
echo "closed rounds: $(grep -lE '^state: closed' "$root"/.bot/campaigns/CAMPAIGN-*/round-*.md | wc -l)"
