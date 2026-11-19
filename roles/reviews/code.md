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
4. **Against the bar:** where the project states how its code is written
   (an implementation document, `AGENTS.md`'s conventions), read each
   component against it: a state carried in tuples or long lists of
   arguments where a type with named fields would hold it, a rule or a
   conversion written in more than one place, an arm or a type no path
   reaches, a lint silenced or worked around rather than answered, a
   comment that tells a history or names the flow's files. Each with
   `file:line`, the rule of the bar it misses, and the change that meets
   it; none is a bug unless it also breaks the design.
5. **Each finding** with `file:line`, checked again at the commit reviewed
   before it enters the report, classified *bug* (the code contradicts the
   design or a rule, or loses data), *hardening* (works today, fails under
   a named condition) or *bar* (works, and falls short of how the project
   writes its code), with its severity.
6. **Separate** what is already in the project's `BACKLOG.md`, citing the
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

## 5. Against the bar
| # | Where (`file:line`) | Rule of the bar it misses | Change that meets it |
|---|---|---|---|

## 6. Items of the earlier round
| # | Item | State | Evidence |
|---|---|---|---|
````
