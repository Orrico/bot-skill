#!/usr/bin/env bash
# usage: prose.sh <bot> — for each file of the skill a model reads: its size in tokens (bytes / 4),
# the share of bytes that are bold markers and wrap indentation, Markdown links, horizontal
# rules, sentences over 40 words and words per sentence. Reads only.
set -u
cd "${1:?usage: prose.sh <bot>}"
files=(SKILL.md models.md roles/*.md roles/manager/*.md roles/reviews/*.md roles/templates/*.md)
printf '%-26s %6s %6s %6s %5s %4s %5s %5s\n' file tok~ bold% indent% links hr sent40 words/s
tb=0 tbold=0 tind=0
for f in "${files[@]}"; do
  b=$(wc -c <"$f"); bold=$(grep -o '\*\*' "$f" | wc -l); ind=$(grep -oE '^ {2,}' "$f" | tr -d '\n' | wc -c)
  ln=$(grep -oE '\]\([^)]+\)' "$f" | wc -l); hr=$(grep -cx -- '---' "$f")
  read -r long avg < <(perl -0ne 's/```.*?```//gs; s/^\|.*$//mg; s/\n(?!\n)/ /g; s/\*\*//g;
    for (split /(?<=[.;:])\s+(?=[A-Z`(-])|\n\n/) { my @w = split /\s+/; next if @w < 3; $s++; $t += @w; $n++ if @w > 40 }
    printf "%d %.0f\n", $n, $s ? $t/$s : 0' "$f")
  awk -v f="$f" -v b=$b -v bo=$bold -v i=$ind -v l=$ln -v h=$hr -v n=$long -v a=$avg 'BEGIN{printf "%-26s %6d %5.1f%% %5.1f%% %5d %4d %5d %5d\n", f, b/4, bo*200/b, i*100/b, l, h, n, a}'
  tb=$((tb+b)) tbold=$((tbold+bold*2)) tind=$((tind+ind))
done | sort -k2 -rn
