The `Role` section names the executor's files: `DEV.md`, `TESTER.md`, or
both, as the `executor` field says.

````markdown
---
id: TASK-nnn
project: <name>
created: YYYY-MM-DD
state: open
campaign: <CAMPAIGN-nnn, if any>
round: <N, if in a campaign>
executor: dev | tester | dev+tester
tier: execution | complex
plan: no | yes
critical_zone: no | yes — <which>
reference: <previous TASK, if any>
---

# TASK-nnn — <short title>

## Role
Read `<bot>/roles/DEV.md` [and `<bot>/roles/TESTER.md`]
before anything else; they hold the rules of conduct and the format of the
result. Rules of this TASK:
- <only what this TASK adds>

## Context
<the problem, why it matters, references: file:line, commits>

## Objective
<one sentence>

## Scope
- Includes:
- Excludes:

## Files
| File | Action | What |
|---|---|---|
| `<path>` | edit / create | <what changes> |

Do not touch: <files or areas nearby that look related but stay out>

## Tests
<with a tester: each test by file and name, the behaviour it shows, and
whether it must fail on the current code (new behaviour) or pass on it
(behaviour that exists); otherwise "none">

## Acceptance criteria
- [ ] `<command>` → <expected result>

## Constraints
<specific to this TASK>

## Deliverable
Do not change this file. Save the result in `.bot/tasks/TASK-nnn-result.md`,
in the format your role files give.
````
