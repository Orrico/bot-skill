# Design

How the skill works now, and the decisions in force with their reasons. A
replaced decision leaves this file for the [CHANGELOG](CHANGELOG.md).

## The data

Everything the work knows is a file in the project's `.bot/` (laid out in
the [README](README.md)). Each file has one writer; the others read it.

Counts are per project, measured on 2026-11-19 over three projects (A, B, C
in [`measurements/`](measurements/)). Shapes, writers and readers are given
by the role files.

| Datum | Shape | States | Count | Writer | Read by |
|---|---|---|---|---|---|
| campaign | scope, goal, completion commands, a row per round | `draft` → `confirmed` → `done` \| `stopped` | 2–20 | MANAGER | MANAGER, AUTO |
| round | a plan (one row per item: kind, executor, exec/review models, TASK → commit), a log, a report | `draft` → `confirmed` → `closed`; each row `todo` → `done` \| `blocked` \| `dropped` | 8–76 | MANAGER; the log under AUTO | the next round's plan, `round-close.sh` |
| TASK | the order: files, data, tests, acceptance commands, tier (`trivial` \| `standard` \| `complex` \| `deep`); frozen once handed over, but for `state` | `open` → `delivered` → `validated` \| `rejected` | 28–320 | MANAGER | the executor, REVIEWER, `task-preflight.sh` |
| result | changed files, each command with its real output, what was missing in the environment | `done` \| `partial` \| `blocked`; up to 5 send-backs | one per TASK | the executor; the MANAGER appends the validation | MANAGER, REVIEWER |
| review | the real diff against the TASK, each criterion run, each condition mutated, findings | a suggested verdict | 0–65 (mandatory since 2026-11-09) | REVIEWER | MANAGER |
| report | a review by kind (`--code`, `--design`, …) | rounds of the same subject | 1–28 | REVIEWER | MANAGER, `/bot learn` |
| knowledge | one lesson per file, an index line each | — | 0–17 | `/bot learn` only | every boot reads `INDEX.md` alone |
| standard files | the project's `README`, `AGENTS`, `DESIGN`, `BACKLOG`, `CHANGELOG` | — | 5 | MANAGER (what a TASK made true), ARCHITECT (decisions) | everyone |
| the code | the project's tree, and one local commit per validated TASK | — | — | the executor; the MANAGER commits | REVIEWER, read only |

The skill's own files are data too, read by models on every turn they stay
in context. What is read, by whom, and when, decides where a rule goes:

| File | Read by | When |
|---|---|---|
| `SKILL.md` | every `/bot` session | at the call |
| `roles/BASE.md` | MANAGER, ARCHITECT, REVIEWER (not as a TASK's delegate), AUTO, WORKER | every turn of their sessions |
| `roles/MANAGER.md` | the MANAGER | every turn of a campaign |
| `roles/REVIEWER.md` | the REVIEWER; alone, as a TASK's delegate | every turn of a review |
| `roles/DEV.md`, `TESTER.md`, `WRITER.md`, `READER.md` | one delegate each, alone | every turn of a TASK |
| `roles/<role>/auto.md`, `roles/manager/task.md`, `roles/manager/learn.md` | a role under AUTO; writing a TASK; a harvest | on demand |
| `roles/reviews/<kind>.md`, `models.md` | a review by kind; the MANAGER picking a model | on demand |
| `roles/templates/` | `new.sh` | when a file is created |

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

## Decisions in force

1. **The state of the work is in files, one writer each.** No role knows
   the conversation that wrote a file, and any model in any CLI can pick the
   work up from it.
2. **`.bot/` lives outside the project's git,** with a git of its own and
   no remote: the project keeps no trace of the way it was worked on.
3. **Executors carry all they need.** DEV, TESTER, WRITER and READER read
   their own files alone, so a delegate may be any model. Of 41 classified
   send-backs, 3 were an executor straying from its files.
4. **A TASK's delegate reviewer reads `REVIEWER.md` alone,** which holds
   what it needs of BASE. A delegated review fell from 254k to 181k input
   tokens in the same turns.
5. **What a session does not use is read on demand** (`roles/<role>/`):
   every line of a role file is reread on every turn it stays in context.
   TASK-writing rules and the 21 pre-handover checks live in
   `roles/manager/task.md`, read only when writing a TASK.
6. **A check that can be decided by a program is a script** — `new.sh`,
   `task-preflight.sh`, `round-close.sh`, `mutate.sh`. Prose rules leaked: 3
   of 112 closed rounds had a row left open, and one TASK passed the
   send-back limit unnoticed.
7. **The MANAGER's checks before a TASK goes out are a numbered list,** one
   check per line: 37 of 41 classified send-backs were gaps of the TASK,
   most under the two densest paragraphs the list replaced.
8. **Lean delegates with usage telemetry:** `claude` runs with its role's
   tools alone — no MCP, no skills — cutting fixed context from 27.7k to
   15.9k tokens (`--bare` reads only an API key, never the subscription's
   login). `agy` runs with `--disable-slash-commands`, `--output-format
   json`, and `bwrap` masks over skills, plugins and `mcp_config.json`
   (cutting 787 tokens/request with 0 MCPs and isolating delegates from
   ambient plugins/MCPs). `delegate.sh` resolves tiers and `auto` directly
   from `models.md`, supports `-e <effort>` (`--effort`), and prints token
   and turn usage for both CLIs.
9. **Send-backs and anti-loop:** 2 per TASK; 3 to 5 only on the user's word,
   never under AUTO; `delegate.sh` refuses the 6th. Executors and reviewers
   stop and report `blocked` (or mark not run) after two failed attempts
   without new progress.
10. **Models by tier in `models.md` alone:** four execution tiers
    (`trivial`, `standard`, `complex`, `deep`) and three review tiers
    (`review-check`, `review-validate`, `review-deep`), paired across CLIs
    with effort levels, plus `READER` on `gemini-3.8-flash-high` / `haiku`
    (`high`). Review tier and `plan:` derive by default from the TASK's
    `tier` and `critical_zone`, overridden only when needed; the round's
    `Model` column names `<exec> / <review>`. Escalation up one tier occurs
    only on a second `executor`-caused send-back, an anti-loop stop, or an
    `executor`-caused re-issue (capped at `complex` under AUTO); TASK-caused
    and first `executor` send-backs stay on the same tier.
11. **A change meant to make the skill cheaper or more reliable** starts
    from the last record of `measurements/` and ends with a new one.
