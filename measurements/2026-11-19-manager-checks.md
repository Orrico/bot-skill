# 2026-11-19 — the MANAGER's checks as a list

MANAGER §4's two densest items — "Decisions resolved in the TASK" (34 lines)
and "A test for each condition" (20 lines) — with "A count in a criterion",
"A bound the TASK sets" and the detail of "Acceptance criteria verifiable by
command", became 21 numbered checks at the end of §4, one per line, "trigger
→ action", grouped by the TASK's section they fill. Each clause of the old
text was mapped to a check; none was dropped. Why: the baseline's section 2
— 37 of 41 classified send-backs are gaps of the TASK, `tests` 18 of them.

## Prose

**Method:** `tools/prose.sh <bot>`, before and after.

| `roles/MANAGER.md` | Before | After |
|---|---|---|
| Tokens (bytes / 4) | 5,358 | 5,211 |
| Sentences over 40 words | 16 | 11 |
| Words per sentence | 23 | 21 |

The file is smaller although the checks take more lines: the description of
what `task-preflight.sh` checks, said twice before, is said by the script's
output now.

## To measure again

`tools/sendback-causes.sh` over the rounds closed after this change, against
the baseline: `tests` 18 of 41 classified causes (44%), the TASK's causes 37
of 41. Rounds closed since the causes became a set are few; wait for about as
many classified send-backs (40) before reading a difference.
