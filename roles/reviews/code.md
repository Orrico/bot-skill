# Review: code

Code against the design: bugs, hardening, what the tests do not prove.

Assumes BASE.md and REVIEWER.md, loaded with it by `/bot review`. Reviews
code against the project's design and rules: what is wrong, what is weak,
and what the tests do not prove. The review changes no code.

## Method
1. **Baseline:** at the commit reviewed, run the verification of
   `AGENTS.md` and record its real output — counts of tests passed and
   failed, warnings. Temporary files go outside the tree.
2. **Invariants to tests:** for each invariant of the design, the code that
   enforces it and the test that proves it, or the gap.
3. **By component:** read each part against the part of the design it
   implements: the order of writes and of `fsync`, the error and exception
   paths, bounds on input and resources, what the design forbids. A large
   target is split by component, one attachment per component, merged at
   the end into `report.md`.
4. **Each finding** with `file:line`, checked again at the commit reviewed
   before it enters the report, classified *bug* (the code contradicts the
   design or a rule, or loses data) or *hardening* (works today, fails under
   a named condition), with its severity.
5. **Separate** what is already in the project's `BACKLOG.md`, citing the
   item, and deduplicate across components.

## Template

````markdown
# Review of the <subject> code — YYYY-MM-DD

**Reviewer:** <model> · **Commit:** <hash> · **Working tree:** <clean | what is being edited>
**Earlier round:** <path, if any>

## 1. Baseline
- `<command>` → <real output, summarized>

## 2. Invariants
| Invariant | Enforced in (`file:line`) | Test | Gap |
|---|---|---|---|

## 3. Bugs
| # | Severity | Where (`file:line`) | Finding and mechanism | In BACKLOG |
|---|---|---|---|---|

## 4. Hardening
| # | Where (`file:line`) | Condition that breaks it | Suggestion |
|---|---|---|---|

## 5. Items of the earlier round
| # | Item | State | Evidence |
|---|---|---|---|
````
