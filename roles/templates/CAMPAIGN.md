The campaign's file, `.bot/campaigns/CAMPAIGN-nnn/campaign.md`. Each round is
a file of its own beside it, in the form of `ROUND.md`.

````markdown
---
id: CAMPAIGN-nnn
project: <name>
created: YYYY-MM-DD
state: draft
---

# CAMPAIGN-nnn — <short title>

## Scope
<the user's words or the BACKLOG items, literal>

## Goal
<one sentence>

## Completion
- [ ] `<command>` → <expected result>

## Left out
- <item> — <why: the decision it waits on, critical zone, out of the scope, already done at <commit> (`file:line`)>

## Rounds
| # | State | Summary |
|---|---|---|
| 1 | draft / confirmed / closed | <one line, written when the round closes> |
````
