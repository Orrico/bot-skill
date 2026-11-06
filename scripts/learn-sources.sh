#!/usr/bin/env bash
# usage: learn-sources.sh <root> [--list | --mark]
#   (no flag)  prints what the next harvest reads from .bot/ and the CHANGELOG
#              (new files whole, changed files as a diff), and extracts the new
#              lines of the conversations to a temporary folder, printing its path
#   --list     prints only the sources, new or changed, with sizes and a token estimate
#   --mark     records as digested the sources of the last run (commits pending
#              sources in .bot first)
set -eu
root=$(cd "${1:?usage: learn-sources.sh <root> [--list|--mark]}" && pwd)
mode=${2:-}
bot="$root/.bot"
ledger="$bot/knowledge/.ledger"
sources=(tasks campaigns reports)
projects="$HOME/.claude/projects"
slug=$(printf '%s' "$root" | sed 's/[^A-Za-z0-9]/-/g')
name=$(basename "$root")
git -C "$bot" rev-parse --git-dir >/dev/null 2>&1 || { echo "no git in $bot" >&2; exit 1; }

# conversation text: the user's and the assistant's words, no tool results, no meta, no sidechains
extract() {
  jq -r '
    if .type == "user" or .type == "assistant" then
      select((.isMeta != true) and (.isSidechain != true))
      | .type as $t
      | (.message.content | if type=="string" then . else ([.[]? | select(.type=="text") | .text] | join("\n")) end)
      | select(length>0) | "[\($t)] \(.)"
    elif .type == "USER_INPUT" then
      (.content // "" | if test("<USER_REQUEST>") then capture("<USER_REQUEST>(?<req>.*?)</USER_REQUEST>"; "s").req else . end | gsub("^\\s+|\\s+$"; "") | select(length > 0) | "[user] \(.)")
    elif .type == "PLANNER_RESPONSE" then
      (.content // "" | gsub("^\\s+|\\s+$"; "") | select(length > 0) | "[assistant] \(.)")
    else empty end
  ' 2>/dev/null || true
}

conv_name() {
  case "$1" in
    */brain/*/.system_generated/logs/*) basename "$(dirname "$(dirname "$(dirname "$1")")")" ;;
    *) basename "$1" .jsonl ;;
  esac
}

# transcripts of the project:
# 1. Claude Code: its own folder, plus /bot sessions on it opened from other workspaces;
# 2. agy: conversation_summaries.db matching the workspace, plus its transcript.jsonl
transcripts() {
  if [ -d "$projects" ]; then
    [ -d "$projects/$slug" ] && ls "$projects/$slug"/*.jsonl 2>/dev/null || true
    grep -l -m1 '<command-name>/bot</command-name>' "$projects"/*/*.jsonl 2>/dev/null \
      | grep -v "^$projects/$slug/" \
      | while IFS= read -r f; do
          grep -q -m1 -E "<command-args>[^<]*(\b$name\b|$root)" "$f" && echo "$f" || true
        done || true
  fi

  for agy_dir in "$HOME/.gemini/antigravity-cli" "$HOME/.gemini/antigravity"; do
    local agy_db="$agy_dir/conversation_summaries.db"
    local agy_brain="$agy_dir/brain"
    if [ -f "$agy_db" ] && command -v sqlite3 >/dev/null 2>&1; then
      local q=${root//\'/\'\'}
      sqlite3 "$agy_db" "SELECT conversation_id FROM conversation_summaries WHERE (parent_conversation_id IS NULL OR length(parent_conversation_id) = 0) AND (instr(workspace_uris, 'file://$q\"') > 0 OR instr(workspace_uris, 'file://$q/roles\"') > 0);" \
        | while IFS= read -r cid; do
            [ -n "$cid" ] || continue
            local f="$agy_brain/$cid/.system_generated/logs/transcript_full.jsonl"
            [ -f "$f" ] || f="$agy_brain/$cid/.system_generated/logs/transcript.jsonl"
            [ -f "$f" ] && echo "$f" || true
          done || true
    fi
  done
  true
}
digested() { # lines of a transcript already digested
  awk -F'\t' -v f="$1" '$1==f {n=$2} END {print n+0}' "$ledger/transcripts.tsv" 2>/dev/null || echo 0
}

if [ "$mode" = --mark ]; then
  mkdir -p "$ledger"
  existing=()
  for s in "${sources[@]}"; do [ -e "$bot/$s" ] && existing+=("$s"); done
  if [ ${#existing[@]} -gt 0 ]; then
    git -C "$bot" add -- "${existing[@]}"
    git -C "$bot" diff --cached --quiet -- "${existing[@]}" || git -C "$bot" commit -q -m "chore: sources of the harvest" -- "${existing[@]}"
  fi
  git -C "$bot" rev-parse HEAD > "$ledger/bot"
  if [ -f "$root/CHANGELOG.md" ]; then cp "$root/CHANGELOG.md" "$ledger/CHANGELOG.md"; else rm -f "$ledger/CHANGELOG.md"; fi
  if [ -f "$ledger/transcripts.pending.tsv" ]; then
    touch "$ledger/transcripts.tsv"
    awk -F'\t' 'NR==FNR {p[$1]=$2; next} !($1 in p) {print} END {for (f in p) print f"\t"p[f]}' \
      "$ledger/transcripts.pending.tsv" "$ledger/transcripts.tsv" | sort > "$ledger/transcripts.tsv.new"
    mv "$ledger/transcripts.tsv.new" "$ledger/transcripts.tsv"
    rm "$ledger/transcripts.pending.tsv"
    t="$(wc -l < "$ledger/transcripts.tsv") transcripts"
  else
    t="no conversation extracted"
  fi
  echo "marked: .bot $(cut -c1-7 "$ledger/bot"), CHANGELOG $( [ -f "$ledger/CHANGELOG.md" ] && echo copied || echo absent ), $t"
  exit 0
fi

since=$(cat "$ledger/bot" 2>/dev/null || true)
[ -n "$since" ] && ! git -C "$bot" cat-file -e "$since^{commit}" 2>/dev/null && { echo "ledger commit $since not found in .bot" >&2; exit 1; }
if [ -n "$since" ]; then echo "since: .bot ${since:0:7}"; else echo "since: no harvest yet, everything is new"; fi

new=() changed=()
for s in "${sources[@]}"; do
  [ -e "$bot/$s" ] || continue
  if [ -z "$since" ]; then
    while IFS= read -r f; do new+=("$f"); done < <(cd "$bot" && find "$s" -type f | sort)
    continue
  fi
  while IFS=$'\t' read -r st f; do
    case "$st" in A) new+=("$f");; M|R*) changed+=("$f");; esac
  done < <(git -C "$bot" diff --name-status "$since" -- "$s")
  while IFS= read -r f; do new+=("$f"); done < <(git -C "$bot" ls-files -o --exclude-standard -- "$s")
done

cl=""
if [ -f "$root/CHANGELOG.md" ]; then
  if [ ! -f "$ledger/CHANGELOG.md" ]; then cl=new
  elif ! cmp -s "$ledger/CHANGELOG.md" "$root/CHANGELOG.md"; then cl=changed; fi
fi

bytes=0
size() { wc -c | tr -d ' '; }

if [ "$mode" = --list ]; then
  for f in "${new[@]}"; do b=$(size < "$bot/$f"); bytes=$((bytes+b)); echo "new      .bot/$f  $b B"; done
  for f in "${changed[@]}"; do b=$(git -C "$bot" diff "$since" -- "$f" | size); bytes=$((bytes+b)); echo "changed  .bot/$f  $b B (diff)"; done
  case "$cl" in
    new) b=$(size < "$root/CHANGELOG.md"); bytes=$((bytes+b)); echo "new      CHANGELOG.md  $b B";;
    changed) b=$( (diff -u "$ledger/CHANGELOG.md" "$root/CHANGELOG.md" || true) | size); bytes=$((bytes+b)); echo "changed  CHANGELOG.md  $b B (diff)";;
  esac
  cbytes=0 cn=0
  while IFS= read -r t; do
    [ -n "$t" ] || continue
    total=$(wc -l < "$t"); done_=$(digested "$t")
    [ "$total" -gt "$done_" ] || continue
    b=$(tail -n +"$((done_+1))" "$t" | extract | size)
    [ "$b" -gt 0 ] || continue
    cbytes=$((cbytes+b)); cn=$((cn+1))
    case "$t" in
      */brain/*) src=agy where=here ;;
      *) src=claude where=$([ "$(dirname "$t")" = "$projects/$slug" ] && echo here || echo "from $(basename "$(dirname "$t")")") ;;
    esac
    echo "talk     $src $(conv_name "$t")  $b B of text, lines $((done_+1))-$total ($where)"
  done < <(transcripts)
  echo "total: ${#new[@]} new, ${#changed[@]} changed${cl:+, CHANGELOG $cl}: $bytes B (~$((bytes/4)) tokens, estimate); conversations: $cn, $cbytes B (~$((cbytes/4)) tokens, estimate)"
  exit 0
fi

for f in "${new[@]}"; do echo "===== new .bot/$f"; cat "$bot/$f"; echo; done
for f in "${changed[@]}"; do echo "===== changed .bot/$f"; git -C "$bot" diff "$since" -- "$f"; done
case "$cl" in
  new) echo "===== new CHANGELOG.md"; cat "$root/CHANGELOG.md";;
  changed) echo "===== changed CHANGELOG.md"; diff -u "$ledger/CHANGELOG.md" "$root/CHANGELOG.md" || true;;
esac

mkdir -p "$ledger"
out=$(mktemp -d -p /tmp)
: > "$ledger/transcripts.pending.tsv"
cn=0
while IFS= read -r t; do
  [ -n "$t" ] || continue
  total=$(wc -l < "$t"); done_=$(digested "$t")
  [ "$total" -gt "$done_" ] || continue
  head -n "$total" "$t" | tail -n +"$((done_+1))" | extract > "$out/$(conv_name "$t").txt"
  printf '%s\t%s\n' "$t" "$total" >> "$ledger/transcripts.pending.tsv"
  if [ -s "$out/$(conv_name "$t").txt" ]; then cn=$((cn+1)); else rm "$out/$(conv_name "$t").txt"; fi
done < <(transcripts)
echo "===== conversations: $cn extracted to $out (read them through the reader, not here)"
echo "===== total: ${#new[@]} new, ${#changed[@]} changed${cl:+, CHANGELOG $cl}, $cn conversations"
