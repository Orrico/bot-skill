#!/usr/bin/env bash
# usage: sendback-causes.sh <root>... — counts the causes of the lines of "Send-backs and
# re-issues" in every round of each project, by the closed set of roles/templates/ROUND.md;
# a line with no cause of the set counts as "none". Reads only.
set -u
[ $# -ge 1 ] || { echo "usage: sendback-causes.sh <root>..." >&2; exit 2; }
for root in "$@"; do
  awk '/^### Send-backs and re-issues/ {on = 1; next} /^##/ {on = 0} on && /^- TASK/' \
    "$root"/.bot/campaigns/*/round-*.md 2>/dev/null
done | sed -E -n 's/.* — `?(tests|data|untried|dependents|rule|executor|environment)`? — .*/\1/p; t; s/.*/none/p' |
  sort | uniq -c | sort -rn
