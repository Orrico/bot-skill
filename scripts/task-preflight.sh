#!/usr/bin/env bash
# usage: task-preflight.sh <root> TASK-nnn [--no-run] [<name>...] — checks a written TASK
# against the current tree, before it is handed over:
#   files     each backticked path in the first cell of a table row whose second cell has no
#             backtick (the "Files" table, not "Data"): there or absent
#   refs      each backticked `path:line`: the file there and that long
#   criteria  each `- [ ] `command`` line: the command run from <root>, its status and last line
#   names     each <name> the TASK changes or removes (a field, a message, an error code), in its
#             snake_case, camelCase, PascalCase and kebab-case forms: the files that hold it,
#             those the TASK does not cite marked
# --no-run lists the criteria without running them. PREFLIGHT_TIMEOUT: seconds allowed to each
# command (default 300). Prints facts only; it always exits 0 once the TASK is found.
set -u
usage='usage: task-preflight.sh <root> TASK-nnn [--no-run] [<name>...]'
[ $# -ge 2 ] || { echo "$usage" >&2; exit 2; }
root=$(cd "$1" && pwd) || exit 2
id=TASK-${2#TASK-}; shift 2
task="$root/.bot/tasks/$id.md"
[ -f "$task" ] || { echo "no $task" >&2; exit 2; }
limit=${PREFLIGHT_TIMEOUT:-300}
run=1 names=()
for a in "$@"; do case "$a" in --no-run) run=0;; *) names+=("$a");; esac; done
cd "$root" || exit 2

echo "files:"
sed -n -E 's/^\| *`([^`<>]+)` *\| *([^|`]*[^|` ]) *\|.*/\1\t\2/p' "$task" | while IFS=$'\t' read -r path action; do
  if [ -e "$path" ]; then there=there; else there=absent; fi
  printf '  %-7s %s (%s)\n' "$there" "$path" "$action"
done

echo "refs:"
checked=0 bad=0
while IFS=: read -r path line; do
  checked=$((checked + 1))
  if [ ! -f "$path" ]; then
    echo "  absent  $path:$line"; bad=$((bad + 1))
  elif [ "$(wc -l < "$path")" -lt "$line" ]; then
    echo "  short   $path:$line ($(wc -l < "$path") lines)"; bad=$((bad + 1))
  fi
done < <(grep -oE '`[^` :]+:[0-9]+' "$task" | tr -d '`' | sort -u)
echo "  $checked checked, $bad wrong"

echo "criteria:"
tmp=$(mktemp -d -p /tmp preflight.XXXXXX)
n=0
sed -n -E 's/^ *- \[[ x]\] *`([^`]+)`.*/\1/p' "$task" > "$tmp/commands"
while IFS= read -r cmd <&3; do
  n=$((n + 1))
  if [ "$run" -eq 0 ]; then echo "  $n. $cmd"; continue; fi
  timeout "$limit" bash -c "$cmd" > "$tmp/$n.log" 2>&1 </dev/null; s=$?
  case "$s" in 0) w=pass;; 124) w="timeout after ${limit}s";; 127) w="command not found";; *) w="fail (exit $s)";; esac
  echo "  $n. $w — $cmd"
  echo "     $(grep -v '^[[:space:]]*$' "$tmp/$n.log" | tail -1 | cut -c1-160)"
done 3< "$tmp/commands"
[ "$n" -gt 0 ] || echo "  none found: no line of the form - [ ] \`command\`"
if [ "$run" -eq 1 ] && [ "$n" -gt 0 ]; then echo "  output: $tmp"; else rm -r "$tmp"; fi

[ ${#names[@]} -gt 0 ] || exit 0
echo "names:"
forms() { # the spellings of one identifier; any other text, as it is
  local name=$1 words w camel="" pascal=""
  echo "$name"
  [[ $name =~ ^[A-Za-z0-9_-]+$ ]] || return 0
  words=$(echo "$name" | sed -E 's/([a-z0-9])([A-Z])/\1 \2/g; s/[_-]+/ /g' | tr '[:upper:]' '[:lower:]')
  echo "${words// /_}"; echo "${words// /-}"
  for w in $words; do
    pascal+="${w^}"
    if [ -z "$camel" ]; then camel=$w; else camel+="${w^}"; fi
  done
  echo "$camel"; echo "$pascal"
}
for name in "${names[@]}"; do
  args=()
  while IFS= read -r f; do args+=(-e "$f"); done < <(forms "$name" | sort -u)
  echo "  $name ($(forms "$name" | sort -u | paste -sd' ' -)):"
  hits=$(git grep -c -I --untracked -F "${args[@]}" 2>/dev/null)
  [ -n "$hits" ] || { echo "    in no file"; continue; }
  while IFS= read -r line; do
    path=${line%:*}; c=${line##*:}
    if grep -qF -- "$path" "$task"; then mark="         "; else mark="NOT CITED"; fi
    printf '    %s %3d  %s\n' "$mark" "$c" "$path"
  done <<< "$hits"
done
