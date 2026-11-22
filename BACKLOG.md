# Backlog

What is left, by priority. A finished item leaves this file for the
CHANGELOG.

## Measure

1. **The checks' effect on send-backs.** The share of `tests` among the
   classified causes of rounds closed after the MANAGER's checks became a
   list, against 18 of 41. Wait for about 40 classified causes
   (`measurements/2026-11-19-manager-checks.md`).
2. **A real delegated review** reading `REVIEWER.md` alone, by
   `measurements/tools/delegate-usage.sh`, against 254k → 181k on the
   throwaway TASK (`measurements/2026-11-19-roles-review.md`).
3. **The lean delegate on what it has not run:** a mutation through
   `mutate.sh`, and the `agy` path, once each.

## Decide

4. **A goal gate for AUTO in Claude Code.** `/goal` with the campaign's
   completion conditions, and an exit when all that is left is blocked, so
   that a separate evaluator, not the model, decides the run may stop.
   Waits on a design decision; `agy` has no equivalent.
5. **A spend cap per TASK.** `--max-budget-usd` caps a `claude -p` run;
   untested on a subscription. If it holds, `delegate.sh` could take one.

## Fix

6. **`learn-sources.sh` on a project with Antigravity conversations**
   printed `Error: stepping, database disk image is malformed (11)` and
   went on. Find whether the database or the script is at fault.
7. **`roles/WRITER.md`** has 16 prose lines past 80 columns.
