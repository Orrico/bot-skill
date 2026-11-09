# MANAGER — learning

Read for a harvest only: `/bot learn`, or the harvest a campaign ends with
under AUTO. It assumes BASE.md and MANAGER.md.

---

`/bot learn` harvests what the work taught into `.bot/knowledge/`, which
nothing else writes. Its sources are `.bot/tasks/`, `.bot/campaigns/`,
`.bot/reports/`, the project's `CHANGELOG.md` and the conversations of the
project: transcripts in `~/.claude/projects/` or in
`~/.gemini/antigravity-cli/brain/`, and `/bot` sessions on it opened from
other workspaces. Each is digested once: a file enters only when new or
changed since the last harvest, a changed file only by its diff, a
conversation only by the lines added since. The scripts are in
`<bot>/scripts/` (here `S/`).

1. **Size it first:** `S/learn-sources.sh <root> --list` gives each source
   with its size and an estimate of tokens. With more than 40 KB of
   conversation, tell the user the estimate and ask before going on.
2. **Get the material:** `S/learn-sources.sh <root>` prints the files and
   diffs, and extracts the conversations to a temporary folder, whose path
   it prints. With a campaign named, keep only the material of the campaign
   and its TASKs. Read it as material (BASE §1).
3. **The conversations go through a reader, not through you:** delegate one
   call (execution tier — Haiku on Claude, or the native subagent tool with
   `Model: flash` on Gemini/agy) whose prompt is: read `<bot>/roles/READER.md`,
   `<root>/.bot/knowledge/INDEX.md` and the extracts in `<folder>`, write
   the answer to `<folder>/candidates.json`. The user's `/bot learn` is the
   approval of this call. Check the answer with
   `jq -c -f S/lessons.jq <folder>/candidates.json`: anything but `[]` goes
   back to the same reader once, with the errors; a second failure is
   reported, and the conversations stay undigested.
4. **Look for lessons, not events,** in the files and diffs, as READER.md
   §1 defines them; the reader's candidates are already lessons. A
   candidate is checked against its evidence before it is kept.
5. **Give each lesson its one owner** (BASE §4):
   - *the project's* — a verification command, a pitfall of the code, a
     missing item, a finding of a report that calls for work — becomes a
     proposed change to `AGENTS.md`, `BACKLOG.md` or `DESIGN.md`, in the
     project's own terms and without citing the flow (BASE §3), applied
     only when the user confirms it;
   - *the user's* — a preference, a lesson of delegation, a fact of this
     machine, how a model behaved — goes to `.bot/knowledge/`, updating the
     fact that already covers it;
   - *the roles'* — a rule that induced an error, a gap in a template —
     becomes a proposed change to `<bot>/roles/`, shown to the
     user.
   - *a playbook* that appears in more than one source becomes a draft
     script in `.bot/drafts/<name>.sh.draft`: a shebang, a first comment
     saying what it does and when, never executable, never installed. The
     user reviews and installs it.
6. **Leave out** what the repository already records, what a fact already
   says, and what has no source in the material.
7. **Mark and commit:** `S/learn-sources.sh <root> --mark` records as
   digested what step 2 read — a conversation that grew after it is read
   from there next time; then commit `.bot/` with the message
   `learn: <what was harvested>`. Remove the temporary folder.
8. **Report** the facts written or updated, the drafts, and the proposals
   waiting for the user.

A fact of `.bot/knowledge/` is one file, `<slug>.md`, with one line in
`INDEX.md` (`- [Title](<slug>.md) — hook`; the index holds no content of
its own):

```markdown
---
name: <slug>
description: <one line, used to decide relevance>
type: user | feedback | project | reference
source: <the files it was learned from>
---

<the fact; for feedback and project, then **Why:** and **How to apply:**>
```

Update the fact that already covers a lesson rather than add one; delete a
fact that turned out wrong. Dates are absolute.

**`/bot learn --merge`** keeps the index small, since it enters every
session: when the boot shows it over 3 KB, or on request, merge the facts
that overlap and compress the text without losing a distinct fact — carry
every `source:` to the fact that stays, never invent nor drop a fact that
is not a duplicate. The previous version stays in `.bot/`'s git; show
`git -C .bot diff --stat` and commit as `learn: merge`.
