#!/usr/bin/env bash
# usage: status.sh <root> — prints the roles /bot can load and the state of a project
set -eu
root=$(cd "${1:?usage: status.sh <root>}" && pwd)
here=$(cd "$(dirname "$(readlink -f "$0")")" && pwd)
roles=$(cd "$here/../roles" && pwd)
bot="$root/.bot"

echo "roles: $roles"
for f in "$roles"/*.md; do
  printf '  %-12s %s\n' "$(basename "$f" .md)" "$(sed -n 1p "$f" | sed -E 's/^# [^—]*— ?//')"
done
echo "review kinds: $roles/reviews"
for f in "$roles"/reviews/*.md; do
  printf '  %-12s %s\n' "$(basename "$f" .md)" "$(sed -n 3p "$f")"
done

echo
echo "project: $root"
instructions=""
for f in AGENTS.md CLAUDE.md GEMINI.md; do [ -f "$root/$f" ] && instructions="$instructions $f"; done
echo "instructions:${instructions:- none}"
if git -C "$root" rev-parse --git-dir >/dev/null 2>&1; then
  echo "git: $(git -C "$root" branch --show-current) @ $(git -C "$root" rev-parse --short HEAD), $(git -C "$root" status --porcelain | wc -l) changed"
  echo "last commit: $(git -C "$root" log -1 --format='%ad %s' --date=short)"
fi
if [ -d "$bot" ]; then
  count() { ls "$1" 2>/dev/null | grep -oE "^$2-[0-9]{3}" | sort -u | wc -l; }
  echo "bot files: $(count "$bot/tasks" TASK) TASKs, $(count "$bot/campaigns" CAMPAIGN) campaigns, $(ls "$bot/reports" 2>/dev/null | wc -l) reports"
fi
echo
"$here/boot.sh" "$root" | grep -vE '^(root|git):' || true
