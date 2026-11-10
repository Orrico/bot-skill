#!/usr/bin/env bash
# usage: mutate.sh <root> <file> <old> <new> -- <test command>... — breaks one condition and
# tells whether the tests see it: replaces <old>, found exactly once in <file>, by <new>, runs
# the command from <root>, restores the file by copy and runs the command twice more.
# Exit: 0 killed (the mutated run failed), 1 survived (it passed), 2 not run (usage, <old> not
# found once, the edit did not take), 3 the tests fail on the restored file.
# MUTATE_TIMEOUT: seconds allowed to each run (default 600). The runs' output is kept, in the
# folder printed as "output:", unless the mutation was killed by a failing test.
set -u
usage='usage: mutate.sh <root> <file> <old> <new> -- <test command>...'
[ $# -ge 6 ] && [ "$5" = -- ] || { echo "$usage" >&2; exit 2; }
root=$(cd "$1" && pwd) || exit 2
file=$2 old=$3 new=$4; shift 5
limit=${MUTATE_TIMEOUT:-600}
cd "$root" || exit 2
[ -f "$file" ] || { echo "not run: no file $file under $root" >&2; exit 2; }
[ -n "$old" ] || { echo "not run: <old> is empty" >&2; exit 2; }

content=$(cat "$file"; printf x); content=${content%x}
without=${content//"$old"/}
count=$(( (${#content} - ${#without}) / ${#old} ))
[ "$count" -eq 1 ] || { echo "not run: <old> found $count times in $file, must be 1" >&2; exit 2; }

tmp=$(mktemp -d -p /tmp mutate.XXXXXX)
cp -p "$file" "$tmp/original"
restore() { cat "$tmp/original" > "$file"; }
trap 'restore; exit 2' INT TERM HUP

printf '%s' "${content/"$old"/"$new"}" > "$file"
if cmp -s "$tmp/original" "$file"; then
  echo "not run: the edit left $file as it was" >&2; exit 2
fi

run() { # the test command under the time limit, its output in $out, its status returned
  timeout "$limit" "$@" > "$out" 2>&1
}
word() { case "$1" in 0) echo pass;; 124) echo "timeout after ${limit}s";; *) echo "fail (exit $1)";; esac; }

out="$tmp/mutated.log"; run "$@"; mutated=$?
restore
trap - INT TERM HUP
if ! cmp -s "$tmp/original" "$file"; then
  echo "RESTORE FAILED: $file differs from $tmp/original" >&2; exit 3
fi
touch "$file"
out="$tmp/restored-1.log"; run "$@"; first=$?
out="$tmp/restored-2.log"; run "$@"; second=$?

echo "mutation: $file: $(printf '%s' "$old" | head -1) -> $(printf '%s' "$new" | head -1)"
echo "command: $*"
if [ "$mutated" -eq 0 ]; then
  echo "mutated run: pass — SURVIVED: no test sees this condition"
else
  case "$mutated" in
    124) echo "mutated run: $(word 124) — killed, if the log shows the mutation and not a slow run";;
    *) echo "mutated run: $(word "$mutated") — killed";;
  esac
  grep -m 5 -iE 'fail|panicked|error|assert' "$tmp/mutated.log" | cut -c1-200 | sed 's/^/  /'
fi
echo "restored: identical to the original; runs after it: $(word "$first"), $(word "$second")"
if [ "$second" -ne 0 ]; then
  echo "INVALID: the tests fail on the restored file; the verdict above proves nothing"
  echo "output: $tmp"
  exit 3
fi
case "$mutated" in
  0) echo "output: $tmp"; exit 1;;
  124) echo "output: $tmp"; exit 0;;
  *) rm -r "$tmp"; exit 0;;
esac
