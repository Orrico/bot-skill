#!/usr/bin/env bash
# usage: co-edit.sh <root> <file>... [-n <commits>] — lists the files most often changed in the
# same commits as the given ones, over the last commits (default 300): candidates to inspect
# for a TASK's "Files" or "Do not touch", not files to edit
set -eu
root=$(cd "${1:?usage: co-edit.sh <root> <file>... [-n <commits>]}" && pwd); shift
n=300 files=()
while [ $# -gt 0 ]; do
  case "$1" in -n) n=$2; shift 2;; *) files+=("$1"); shift;; esac
done
[ ${#files[@]} -gt 0 ] || { echo "no file given" >&2; exit 1; }

git -C "$root" log -n "$n" --format='@%h' --name-only -- . | awk -v targets="$(printf '%s\n' "${files[@]}")" '
  BEGIN { split(targets, t, "\n"); for (i in t) if (t[i] != "") want[t[i]] = 1 }
  /^@/ { flush(); next }
  NF { files[++k] = $0 }
  END { flush()
        for (f in co) printf "%d\t%d%%\t%s\n", co[f], 100 * co[f] / hits, f | "sort -rn | head -15"
        if (!hits) print "none of the files changed in the last commits read" > "/dev/stderr" }
  function flush(   i, hit) {
    hit = 0; for (i = 1; i <= k; i++) if (files[i] in want) hit = 1
    if (hit) { hits++; for (i = 1; i <= k; i++) if (!(files[i] in want)) co[files[i]]++ }
    k = 0; delete files }'
