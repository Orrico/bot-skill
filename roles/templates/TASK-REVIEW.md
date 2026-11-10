````markdown
---
id: TASK-nnn
reviewer: <model>
date: YYYY-MM-DD
suggested_verdict: validate | reject | validate with reservations
---

# Review — TASK-nnn

## Files
| File | In the TASK | In the result | In the diff | Note |
|---|---|---|---|---|

## Data
| Datum | In the TASK | In the diff | Note |
|---|---|---|---|

## Acceptance criteria
- [x|  ] <criterion> — `<command>` → <real output, summarized>; <matches | differs from the reported: how>

## Constraints
- [x|  ] <constraint> — <evidence: file:line or command>

## Mutations
| Condition (`file:line`) | Edit | Test that failed |
|---|---|---|
| <the condition> | <the edit made> | <test name, or "none": then a finding> |

## Findings
| # | Severity | Where (`file:line`) | Finding and mechanism |
|---|---|---|---|

## Defects of the TASK
<what in the TASK induced or allowed an error; "none" if nothing>

## Summary
<two or three sentences: what is ready, what prevents validating, what the MANAGER should look at first>
````

