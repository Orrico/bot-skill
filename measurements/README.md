# Measurements

What was measured about the skill, so the next optimization starts from
numbers and can run the same method again. Nothing here is read by `/bot`.

| Record | Holds |
|---|---|
| [`2026-11-19-baseline.md`](2026-11-19-baseline.md) | closed rounds against `round-close.sh`; the causes of send-backs; the fixed context of a delegate and what the lean flags save; a lean delegate on a real TASK; the placeholder check; the prose a model reads |

## Tools

Each reads only, unless its line says otherwise.

| Tool | Measures |
|---|---|
| [`tools/closed-rounds.sh`](tools/closed-rounds.sh) `<root>` | `round-close.sh` on every closed round of a project, its lines counted by kind |
| [`tools/sendback-causes.sh`](tools/sendback-causes.sh) `<root>...` | the causes of send-backs, by the closed set |
| [`tools/delegate-usage.sh`](tools/delegate-usage.sh) `<transcripts dir>...` | each delegate session: requests, fixed context, input, output, fixed share |
| [`tools/fixed-context.sh`](tools/fixed-context.sh) `<root> [model]` | the input of a one-word `claude -p`, full and lean — **spends two short calls of the user's quota** |
| [`tools/prose.sh`](tools/prose.sh) `<bot>` | per file a model reads: tokens, formatting share, long sentences |

## A new record

- One file per session of measurement, `YYYY-MM-DD-<subject>.md`; a record is
  not edited after it is written, except to mark an error, said so in it.
- Each measurement gives its question, its method (the tool or command), the
  data, its reading, the decision it informed with the commit, and what to
  measure again.
- Projects are named by letter, A, B, C, as in the baseline: this repository
  is public, and a private project's name does not enter it.
- A correction of a method is written down with what it changed in the
  numbers, as the baseline's section 3 does.
