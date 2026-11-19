# /bot

A skill for coding agents — Claude Code and Gemini (Antigravity) — that takes
roles on a project. Each role is a transformation of files: a manager turns a
request into a plan and TASKs, an executor turns a TASK into code and a
result, a reviewer turns a delivery into a review. The files live in the
project's `.bot/` folder, outside the project's git, so the project keeps no
trace of them.

```
/bot <project> [role+role] <request>
```

read as "in project X, as roles Y, do Z":

```
/bot . manager "plan the next round from the backlog"
/bot ~/Code/myapp manager+architect "design the sessions' store"
/bot myapp dev+tester TASK-071
/bot myapp review TASK-012
/bot myapp review --code src/
/bot myapp learn
/bot myapp status
```

The coordinating roles want the strongest model, the executors a cheaper one
([`models.md`](models.md)). In Claude Code, `/model opusplan` plans with Opus
and executes with Sonnet in one session, and switching models keeps the
conversation.

## The data

Everything the work knows is a file. Each file has one writer; the others
read it.

```
.bot/                 its own git, no remote; ignored by the project's git
├── campaigns/        CAMPAIGN-nnn/campaign.md and round-N.md
├── tasks/            TASK-nnn.md, TASK-nnn-result.md, TASK-nnn-review.md
├── reports/          YYYY-MM-DD-<kind>-<subject>.md
├── knowledge/        INDEX.md and one <slug>.md per lesson
├── drafts/           <name>.sh.draft, never executable
└── archive/          records of earlier ways of working
```

| Datum | Shape | States | Writer | Read by |
|---|---|---|---|---|
| campaign | scope, goal, completion commands, a row per round | `draft` → `confirmed` → `done` \| `stopped` | MANAGER | MANAGER, AUTO |
| round | a plan (one row per item: kind, executor, model, TASK → commit), a log, a report | `draft` → `confirmed` → `closed`; each row `todo` → `done` \| `blocked` \| `dropped` | MANAGER; the log under AUTO | the next round's plan, `round-close.sh` |
| TASK | the order: files, data, tests, acceptance commands; frozen once handed over, but for `state` | `open` → `delivered` → `validated` \| `rejected` | MANAGER | the executor, REVIEWER, `task-preflight.sh` |
| result | changed files, each command with its real output, what was missing in the environment | `done` \| `partial` \| `blocked`; up to 5 send-backs | the executor; the MANAGER appends the validation | MANAGER, REVIEWER |
| review | the real diff against the TASK, each criterion run, each condition mutated, findings | a suggested verdict | REVIEWER | MANAGER |
| report | a review by kind (`--code`, `--design`, …) | rounds of the same subject | REVIEWER | MANAGER, `/bot learn` |
| knowledge | one lesson per file, an index line each | — | `/bot learn` only | every boot reads `INDEX.md` alone |
| standard files | the project's `README`, `AGENTS`, `DESIGN`, `BACKLOG`, `CHANGELOG` | — | MANAGER (what a TASK made true), ARCHITECT (decisions) | everyone |
| the code | the project's tree, and one local commit per validated TASK | — | the executor; the MANAGER commits | REVIEWER, read only |

## The flow

Each box is a transformation, with the role that runs it; each arrow carries
the data named on it.

```
 a request, BACKLOG.md
       │
       ▼
 PLAN (MANAGER) ── campaign.md, round-N.md (draft) ──► the user confirms the round
       │
       ▼
 SPECIFY (MANAGER) ── new.sh → TASK-nnn.md; task-preflight.sh checks it against the tree
       │
       ▼
 EXECUTE (DEV, TESTER, WRITER — delegate.sh, or by hand) ── the code, TASK-nnn-result.md
       │                                         ▲
       ▼                                         │ a gap inside the TASK: the MANAGER sends it back
 REVIEW (REVIEWER — delegate.sh) ── TASK-nnn-review.md, mutate.sh on each condition
       │
       ▼
 VALIDATE (MANAGER) ── the result's "Validation"; BACKLOG, CHANGELOG, DESIGN; one commit
       │
       ▼
 CLOSE (MANAGER) ── round-close.sh, the round's report ──► the next round's PLAN
       │
       ▼
 LEARN (/bot learn: MANAGER, READER) ── tasks, rounds, reports, transcripts ──► knowledge/
```

The ARCHITECT works beside the flow: a decision an item waits on is made with
the user and recorded in `DESIGN.md` before the item is planned. AUTO is a
layer over the MANAGER or the REVIEWER: it runs a confirmed scope without
asking, inside a window of authorization, and logs each decision.

## Roles

| Role | Reads | Writes |
|---|---|---|
| MANAGER | the BACKLOG, the round before, results, reviews | campaigns, rounds, TASKs, the validation, the standard files, the commit |
| ARCHITECT | the request, the code, `DESIGN.md` | decisions, a data inventory and its flow, in `DESIGN.md` |
| REVIEWER | a TASK and its result, the real diff, the tree | a review, or a report by kind |
| DEV | one TASK, the code | the files the TASK lists, the result |
| TESTER | one TASK, the code | tests that fail when the rule breaks, its part of the result |
| WRITER | one editorial TASK | the article, the result |
| READER | conversations, extracted for a harvest | lesson candidates, as JSON |
| AUTO | the activation's scope | the log of the run: in the round, or `campaigns/AUTO-YYYY-MM-DD.md` |
| WORKER | a request outside the flow | the files it touches, never `.bot/` |

## Scripts

| Script | Reads | Writes or prints |
|---|---|---|
| `boot.sh`, `status.sh` | `.bot/`, git | the open campaigns and TASKs, the next free numbers |
| `new.sh` | a form of `roles/templates/` | a campaign, round, TASK or review at the next number, with what is known filled |
| `task-preflight.sh` | a TASK, the tree | what is left unfilled; each path, `file:line` and criterion checked; each name the TASK changes, found |
| `co-edit.sh` | git history | the files that usually change with the given ones |
| `delegate.sh` | a TASK | the executor or the reviewer run in `claude` or `agy`; its status, tokens and cost |
| `mutate.sh` | a file, a test command | whether the tests see one condition broken; the file restored |
| `round-close.sh` | a round, its TASKs, git | each row not closed, TASK not validated, commit missing or cause outside the set |
| `learn-sources.sh` | `.bot/`, the CHANGELOG, transcripts | what the next harvest reads, new or changed since the last |
| `lessons.jq` | a reader's `candidates.json` | its errors; `[]` when valid |

## The skill's folder

| Path | Holds |
|---|---|
| [`SKILL.md`](SKILL.md) | how `/bot` reads its arguments and boots |
| [`roles/`](roles/) | one file per role; `BASE.md` is what the coordinating roles share |
| [`roles/manager/`](roles/manager/), [`reviewer/`](roles/reviewer/), [`architect/`](roles/architect/) | a role's parts read on demand: the harvest, the run under AUTO |
| [`roles/reviews/`](roles/reviews/) | one file per kind of review |
| [`roles/templates/`](roles/templates/) | the forms `new.sh` fills |
| [`scripts/`](scripts/) | the scripts above |
| [`models.md`](models.md) | the model behind each tier, in each CLI |
| [`measurements/`](measurements/) | what was measured about the skill, and the tools to measure it again |

The roles name this folder `<bot>`; the scripts find it from where they lie,
so the skill works from wherever it is cloned.

## Install

### By your agent

Paste this into Claude Code or Gemini. Change the folder in step 1 if you
keep your code somewhere else.

```text
Install the /bot skill from https://github.com/Orrico/bot-skill for me.

1. Clone it to ~/Code/bot-skill. If that folder already exists, show me
   what is in it and stop.
2. Link the clone as a skill of each agent CLI I have: ~/.claude/skills/bot
   for Claude Code, ~/.gemini/config/skills/bot for Gemini / Antigravity.
   Create the parent folder if needed. If something already exists at
   that path, show me what it is and ask before replacing it.
3. Keep `.bot/` out of every git repository: add the line `.bot/` to my
   global git excludes file (the one `git config --global
   core.excludesFile` names, or ~/.config/git/ignore if it names none),
   unless the line is already there.
4. Check which of these commands are in my PATH: bash, git, jq, perl,
   flock, timeout (required); sqlite3 (to read Antigravity's
   conversations in `/bot learn`); claude and agy (to delegate work to
   another CLI); bwrap and xdg-dbus-proxy (to delegate to agy). Install
   nothing: list what is missing and how my system would install it.
5. Run this and show me its output:
   for s in ~/Code/bot-skill/scripts/*.sh; do bash -n "$s" && test -x "$s" && echo "ok $s"; done
6. Tell me what you did, what is missing, and how to start: the skill runs
   only when I type /bot, e.g. `/bot . status` in a new session.
```

### By hand

Clone it, link it where each CLI looks for skills, and keep `.bot/` out of
git in every repository:

```
git clone https://github.com/Orrico/bot-skill.git ~/Code/bot-skill
ln -s ~/Code/bot-skill ~/.claude/skills/bot          # Claude Code
ln -s ~/Code/bot-skill ~/.gemini/config/skills/bot   # Gemini / Antigravity
mkdir -p ~/.config/git && echo '.bot/' >> ~/.config/git/ignore   # if core.excludesFile is not set
```

The scripts need `bash`, `git`, `jq`, `perl`, and `flock` and `timeout` as
Linux ships them. The harvest reads Antigravity's conversations with
`sqlite3`. Delegating to another CLI needs `claude` or `agy`, and
delegating to `agy` runs it under `bwrap` with `xdg-dbus-proxy`.

## License

[MIT](LICENSE).
