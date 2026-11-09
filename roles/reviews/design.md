# Review: design

A design: what it guarantees, how it fails, and whether the code matches.

Assumes BASE.md and REVIEWER.md, loaded with it by `/bot review`. Reviews a
design — the project's design document, a proposal, a schema, a protocol —
for what it guarantees and how it fails, before or after it is built.

## Method
1. **State what it must hold:** the requirements and invariants the target
   claims, quoted with `file:line`. A guarantee the design implies but does
   not state is listed as implied.
2. **For each decision:** what it guarantees, the failure modes it leaves
   open (concurrency, partial failure, crash between two writes, bad input,
   growth in data or users), the edge cases, and the alternatives that were
   real, with their trade-off.
3. **Check the data:** does the design state what the data is — shape,
   volume, access pattern, lifetime, owner — and keep an inventory of it
   with one writer per datum? For each structure, does it follow from a
   named access pattern, or is it a hierarchy of types or a graph of
   objects chosen without one? Does each choice name what it gives up?
   Does each fact of the inventory carry its source (given, measured or
   assumed), and does a decision rest on an assumed volume or access
   pattern? A gap, or a decision resting on an assumption, is a finding,
   classified as in step 5.
4. **Against the code,** when there is code: does it do what the design
   says, and does each invariant have a test that fails when it breaks?
   Name the test, or say that none exists.
5. **Classify** each finding: *bug in the design* (a contradiction, an
   invariant that cannot hold, a requirement left uncovered), *hardening*
   (holds today, fails under a named condition), or *suggestion* (an
   alternative with its trade-off).
6. **Separate** what is already in the project's `BACKLOG.md`, citing the
   item.

## Template

````markdown
# <Subject> — design, round N

**Date:** YYYY-MM-DD · **Reviewer:** <model>
**Earlier round:** <path> · **Commits reviewed:** <hashes> · **Working tree:** <clean | what is being edited>

## 1. What it must hold
| # | Requirement or invariant | Where (`file:line`) | Stated / implied |
|---|---|---|---|

## 2. Items of the earlier round
| # | Item | State | Evidence |
|---|---|---|---|

## 3. Findings
### 3.n <title> — <bug | hardening | suggestion>, <severity>
- **Where:** `file:line`
- **Passage:** <checked quotation>
- **Mechanism:** <the concrete failure, and the condition that triggers it>
- **Alternatives:** <each with its trade-off>
- **Recommendation:** <one, with the reason>

## 4. Invariants and their tests
| Invariant | Test that proves it | Fails without it? |
|---|---|---|

## 5. Already in the BACKLOG
- <finding> — <the BACKLOG item that covers it>
````
