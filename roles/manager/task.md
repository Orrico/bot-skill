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
  criterion; "`cargo test -p x --test y z` passes" is.
- **Tests named in the TASK:** with a tester, the "Tests" section gives each
  test by file and name, the behaviour it shows, and whether it must fail or
  pass on the current code.
- **Tier and `plan`:** pick `tier` (`standard`, `complex` or `deep`)
  and `plan` from `<bot>/models.md`.
- **Code dictated whole gets the reviewer's eye before handover:** bound
  every peer `.await` (write, flush, shutdown), release locks and child
  processes before awaiting, check tool settings across their full range
  (`0` and the type's maximum), and write files another process reads whole
  beside and rename.
- **Frozen after handover:** once the user has `TASK-nnn.md`, only `state`
  changes. A send-back does not edit it; a rejection does not reopen it —
  write the next TASK with `reference: TASK-nnn` and, in its context, what
  was missing.

## 2. Checks before the TASK goes out

Each check whose trigger the TASK meets is done; the others are skipped. A
send-back caused by the TASK names the check that would have caught it, or
proposes a new one.

Files
1. Each file of "Files" → `<bot>/scripts/co-edit.sh <root> <file>…`; each
   file it lists goes in "Files" or in "Do not touch". They are candidates
   to inspect, not to edit: a file nobody named stops the executor.
2. The TASK removes or changes a text — a message, an error code, a type, a
   field → `git grep -n` it; each file that writes it and each test that
   pins it goes in "Files", with what changes there. The history does not
   show these, and a test pinning the old behaviour stops the executor.
3. The TASK changes what a call returns → grep each assertion on it — the
   rows or the vector it gives back, the store's reads; each one that
   changes goes in "Files".
4. The TASK hands the executor a command, a tool setting or a type, trait,
   macro or feature — a git call, a flag, a crate feature → run the command
   on the real tool first (testing settings at `0` and the type's maximum)
   and check every named type, trait, macro and feature against the crate's
   manifest. A setting, a hook or a service that a test of the TASK turns
   on for the first time in its file is run there on the real tool too,
   prototype or not.

Tests, each in "Tests" by file and name
5. Each `if`, branch, fallback, filter, `serde` attribute and field the
   change adds → the test that fails without it, or an explicit note that
   it is judged from the code and why no test sees it.
6. A derived list → tested with two parents; with one, its filter goes
   unseen.
7. Each bound → tested at its value and one past, also after a conversion
   that can grow the input.
8. An arm that forwards another function's error → its own test.
9. A rule that limits what an action touches ("only", "alone") → a test with
   something beside it that must stay untouched.
10. A rule over every X → a test with an X the setup does not already reach:
    a setup that triggers the behaviour hides the mutation that removes it.
11. A filter of two conditions → for each, an entry that passes it and fails
    the other.
12. A value the code passes through → a test with a value other than the
    common one.
13. A fake in the tests → it honours every argument it is given, and the
    TASK says what it checks.
14. A test or a mutation asserts a text — an output line, a message, a
    pattern → the literal as the code writes it, found with `git grep` in
    the code and in the test helpers that read it; one taken from a type's
    form makes a check that can never fail.
15. Each mutation the TASK lists → run against the TASK's own cases before
    handover (never only reasoned), verified to fail in a test and not in
    the build, writable against the signatures the TASK gives (one its
    types forbid stops the executor), and not equivalent under the code it
    dictates: a guard another rule covers, a bound whose two sides give the
    same value, a fallback that reproduces the fixture's value turns no
    test red.
    A TASK written with no prototype, its mutations not run before the
    handover, carries instead a table in "Tests" from each condition of
    its rule — every `if`, `else`, match arm, `and` and "only" — to the
    test that fails without it: one row for each branch, and two rows
    share a test only where it drives both.

Criteria
16. Each criterion → its command exactly as it runs from the project's root.
17. A criterion that searches or lists files the TASK creates → `git grep
    --untracked`, or it reads nothing of them.
18. A UI or template change with `Tests: none` → assertions on the compiled
    output: subsections, item counts, modifier classes.
19. A count in a criterion → read from `-- --list` or a run, never from a
    search of attributes, which misses the ones that take arguments.
20. The TASK adds to a function under a length bound → count its lines and
    name the helper that keeps it under.

Last
21. `<bot>/scripts/task-preflight.sh <root> TASK-nnn <name>…`, with each
    name the TASK changes or removes → settle each placeholder left that is
    not the TASK's own text, each path at odds with its action, each
    criterion that fails for a reason other than the missing change, and
    each file not cited.
