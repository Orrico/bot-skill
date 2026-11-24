# MANAGER — writing a TASK

Read on demand when writing a TASK (MANAGER §4). Assumes BASE.md and
MANAGER.md. For `tier`, default `plan`, default review tier and escalation,
read `<bot>/models.md` as material (BASE §1).

---

## 1. Creating and filling

Create with `<bot>/scripts/new.sh <root> task <executor> [CAMPAIGN-nnn#N]
[-r TASK-nnn]`: it takes the next number and fills the frontmatter and the
"Role" section from `<bot>/roles/templates/TASK.md`. Fill each `<…>` it
leaves, keep one value where the frontmatter gives a choice (`no | yes`), and
run the checks (§2) before handover.

- **Self-contained for its executor,** who has no access to this
  conversation. The rules of conduct are in the executor's role files; the
  TASK names them and carries only the rules specific to this TASK — never
  repeat role rules in it.
- **The executor is one delegate, with one or two role files** (`executor`):
  - `dev` — the change, with no new tests, or with tests the TASK gives;
  - `dev+tester` — the change and its new tests, in one call: the delegate
    writes the tests first, proves they fail before the change, and after it
    breaks each condition the change added, adding the test a surviving one
    lacks;
  - `tester` — tests only, for behaviour that already exists: they pass on
    the current code and fail when the rule is broken;
  - `writer` — editorial content, following the project's `EDITORIAL.md`.

  Two calls for one TASK — a tester, then a developer — only when the user
  asks for it.
- **Check the real state before writing** (BASE §5): code, documentation,
  recent commits. The executor does not cross sources; a TASK built on an
  old premise is executed as is.
- **Decisions resolved in the TASK:** the executor decides nothing. Exact
  files, what not to touch, verification commands.
- **The data read from the code:** the "Data" section gives each datum the
  TASK reads or writes — a type, a field, a table, a file, a message, what a
  call its tests assert on gives back — as the code has it now, copied from
  its `file:line` and not from memory or from a type's name: its shape, the
  one writer, the valid range with what happens outside it, and what the
  TASK changes in it. Where the project's design keeps a data inventory,
  each row agrees with it; a difference is a design change (MANAGER §1),
  settled before the TASK.
- **Context by reference:** paths, `file:line`, commits. Short excerpts only
  when indispensable; never whole files.
- **Acceptance criteria verifiable by command:** "it works" is not a
  criterion; "`<test command>` passes" is.
- **Tests named in the TASK:** with a tester, the "Tests" section gives each
  test by file and name, the behaviour it shows, and whether it must fail or
  pass on the current code.
- **Tier and `plan`:** pick `tier` (`standard`, `complex` or `deep`)
  and `plan` from `<bot>/models.md`.
- **Code dictated whole gets the reviewer's eye before handover:** bound
  every peer I/O or async call (write, flush, shutdown), release locks and
  child processes before awaiting, test tool settings at `0` and their type
  maximum, and write files read whole by another process beside and rename.
- **Frozen after handover:** once the user has `TASK-nnn.md`, only `state`
  changes. A send-back does not edit it; a rejection does not reopen it —
  write the next TASK with `reference: TASK-nnn` and, in its context, what
  was missing.

## 2. Checks before the TASK goes out

Each check whose trigger the TASK meets is done; the others are skipped. A
send-back caused by the TASK names the check that would have caught it, or
proposes a new one.

Files
1. Each file of "Files" → `<bot>/scripts/co-edit.sh <root> <file>…`; place
   each listed file in "Files" or "Do not touch" (candidates to inspect,
   not to edit: an unnamed file stops the executor). When a TASK creates
   two or more integration test files sharing fixtures, list their shared
   helper module (e.g. Rust's `tests/common/mod.rs`) in "Files".
2. The TASK removes or changes a text (message, error code, type, field) →
   `git grep -n` it; add every writer and pinning test to "Files" with its
   change. History misses these, and a pinning test stops the executor.
3. The TASK changes what a call returns → grep every assertion on it (rows,
   collections, store reads) and add each affected file to "Files".
4. The TASK names a command, tool setting, type, trait, macro or package
   feature → run the command on the real tool first (testing settings at
   `0` and their type maximum) and check every symbol and feature against
   the package manifest. Any setting, hook or service a test turns on for
   the first time in its file runs on the real tool too, prototype or not.

Tests, each in "Tests" by file and name
5. Each `if`, branch, fallback, filter, serialization attribute or field
   added → the test that fails without it, or an explicit note that it is
   judged from the code and why no test reaches it. When a test must prove
   a field hidden by the public API, name the exact call that observes it.
6. A derived list → tested with two parents; one parent hides its filter.
7. Each bound → tested at its value and one past, including after any
   conversion that can grow the input.
8. An arm that forwards another function's error → its own test.
9. A rule limiting what an action touches ("only", "alone") → a test with
   an adjacent item that must stay untouched.
10. A rule over every X → a test with an X the setup does not already
    reach; otherwise setup hides removing the rule.
11. A two-condition filter → for each condition, an entry that passes it
    and fails the other.
12. A passed-through value → a test with a value other than the common one.
13. A test fake → honours every argument it receives; the TASK states what
    it checks.
14. A test or mutation asserts a text, refusal code or query/stream result
    → read the code that produces it and copy the literal, error code or
    filter rule found with `git grep`; one inferred from a type's form or
    memory can never fail or blocks the executor.
15. Each listed mutation → run against the TASK's cases before handover
    (never reasoned), verified to fail in a test (not the build), valid
    under the TASK's signatures, and non-equivalent (no redundant guard,
    same-value bound or fallback matching the fixture).
    Without a prototype, put a table in "Tests" mapping each condition of
    the rule (`if`, `else`, match arm, `and`, "only") to the test that
    fails without it: one row per branch, sharing a test only when it
    drives both.

Criteria
16. Each criterion → exact command as run from the project's root.
17. A criterion searching or listing files the TASK creates → `git grep
    --untracked`, or it misses them.
18. A UI or template change with `Tests: none` → assertions on compiled
    output (subsections, item counts, modifier classes).
19. A test count in a criterion → read from the test runner's list flag or
    run output, never from grepping attributes (which misses parameterized
    ones).
20. The TASK adds to a function under a length bound → count its lines and
    name the helper that keeps it under.

Last
21. `<bot>/scripts/task-preflight.sh <root> TASK-nnn <name>…` with each
    changed or removed name → settle every stray placeholder, path/action
    mismatch, criterion failing for the wrong reason, and uncited file.
