A round of a campaign, `.bot/campaigns/CAMPAIGN-nnn/round-N.md`: its plan,
written before it runs; its log, while it runs; its report, when it closes.

````markdown
---
campaign: CAMPAIGN-nnn
round: N
created: YYYY-MM-DD
state: draft
---

# CAMPAIGN-nnn, round N — <short title>

## Premise
<the commit it starts from, and each item's state there, checked by command (`git grep`, a test, a run); from round 2, the proposals of the last report taken and the answers they rest on>

## Plan
| # | Item | Kind | Executor | Model | After | TASK | State |
|---|---|---|---|---|---|---|---|
| 1 | <one sentence, verifiable outcome> | task / direct / review | dev / tester / dev+tester / — | <model> / — | — | TASK-nnn → <commit> / report | todo / running / done / blocked / dropped |

## Log
<one line per change the plan does not show: a split, a new order, a send-back or a re-issue with its gap and cause, an item found done; under AUTO, in the form it gives>

## Report
<written when the round closes; it does not retell the log>

### Checks
- `<command>` → <real output, summarized>

### Not done
- <item> — <blocked, dropped, or a TASK that did not execute: its result; or why it never became a TASK>

### Send-backs and re-issues
- TASK-nnn — <cause> — <the gap>

### Lessons
- <for each send-back caused by the TASK: the check the next TASKs make before they are handed over>

### Next
<the proposals for the next round — items to add, from answered blocks and "To review"; items to drop; a change of scope — or "the campaign can close">
````

`<cause>`, in "Send-backs and re-issues", is one word of this set, written
as it is here in any language, one line per cause when a send-back has
two. The first five are the TASK's:

| Cause | The gap |
|---|---|
| `tests` | a condition with no test that fails when it breaks |
| `data` | a datum whose shape, writer or range in the code is not the one the TASK gives |
| `untried` | something else the TASK dictates that does not compile, run or hold on the code |
| `dependents` | a file, a test or a fixture the change breaks, left out of "Files" |
| `rule` | a rule of the TASK that is wrong or has two readings |
| `executor` | the executor strayed from the TASK or from its role files |
| `environment` | a tool, a crash or a limit of the machine |
