# 2026-11-19 — the other roles, by who reads what

A review of the roles beside the MANAGER, asking of each passage who reads
it, how often, and whether they use it. Seven findings; all applied but the
ones marked otherwise.

| # | Finding | Change |
|---|---|---|
| A | A delegate reviewing a TASK read all of BASE and used about five of its rules | it reads `REVIEWER.md` alone, which carries those rules (§1); `delegate.sh` and MANAGER §5 changed with it; a review by kind still reads BASE |
| B | AUTO §5 repeated the MANAGER's commit rules and differed from them on a file changed outside the item | AUTO §5 holds only what AUTO changes in a role's own commit rules |
| C | Which mechanism to delegate by was written in four files | in `models.md` alone; BASE, MANAGER and the harvest point to it |
| D | "Under AUTO" sections read in every session, AUTO or not | in `roles/reviewer/auto.md` and `roles/architect/auto.md`, read with AUTO, as `roles/manager/auto.md` was |
| E | BASE §3 taught how to read `estado:` and one-file campaigns | none is left in six projects (only older file names, in 133 closed TASKs): the note keeps the names |
| F | REVIEWER and TESTER told how `mutate.sh` works inside | the call, what it prints and its limits |
| G | A tip for the user's own session in `models.md` | moved to the README |

## The delegated review

**Method:** the throwaway project and TASK of the baseline's section 5 — the
same TASK in state `delivered`, the same diff — reviewed with `delegate.sh
<root> review TASK-001 claude haiku`, before and after A.

| Review | Prompt reads | Turns | Input | Context at the 2nd request |
|---|---|---|---|---|
| before | BASE + REVIEWER | 12 | 254,482 | 21,418 |
| after | REVIEWER | 12 | 180,555 (−29%) | 15,393 |

**Reading:** each request after the role files are read carries about 6k
fewer tokens; over 12 requests that is the 74k saved. A file read by the Read
tool costs about twice its bytes / 4 in context — line numbers and framing —
so BASE weighed 6k, not the 3.4k `prose.sh` gives it. One run each: the
number of turns varies between runs, the drop per request does not. A longer
review saves the same 6k a request on a larger total. The review after A
held every section of the form and checked that the criterion fails on the
code before the change.

**Re-measure:** a delegated review of a real TASK, by
`tools/delegate-usage.sh`, against these numbers.

## The prose

**Method:** `tools/prose.sh <bot>`; tokens are bytes / 4.

| File | Before | After |
|---|---|---|
| `roles/BASE.md` | 3,626 | 3,445 |
| `roles/REVIEWER.md` | 1,959 | 1,880 |
| `roles/AUTO.md` | 1,301 | 1,241 |
| `roles/ARCHITECT.md` | 867 | 760 |
| `roles/TESTER.md` | 1,336 | 1,325 |
| `roles/MANAGER.md` | 5,211 | 5,172 |
| `models.md` | 813 | 843 |

BASE is read on every turn of every coordinating role; REVIEWER on every
turn of every review.

## Left as they are

DEV, TESTER (but for F), WRITER and READER: 3 of 41 classified send-backs are
an executor's (baseline, section 2). WRITER's 16 lines past 80 columns break
the repository's convention and change nothing for a model.
