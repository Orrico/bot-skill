---
name: bot
description: Takes roles of this skill's roles/ folder on a project, with its state in the project's .bot/. Usage — /bot <project> [roles] <request>, read as "in project X, as roles Y, do Z": /bot myapp dev+tester execute TASK-071; /bot myapp review --code src/; /bot myapp review TASK-012; /bot myapp manager learn --merge; /bot myapp status. The project is required (. for the current workspace); roles join with +; no roles means the owner of the request.
argument-hint: "<project> [role+role] <request | status | review [TASK-nnn | --kind subject] | learn [--merge | campaign]>"
disable-model-invocation: true
---

# /bot

Arguments: `$ARGUMENTS` (if this shows literally, the text after `/bot` in
the user's message). `<bot>` is this skill's directory, the base
directory the harness names (resolve a symlink to it); write it as an
absolute path in any file or prompt another model reads. A role is a file of
`<bot>/roles/` (BASE is `<bot>/roles/BASE.md`); the scripts are in
`<bot>/scripts/`.

## 1. Read the arguments
A sentence — in project X, as roles Y, do Z, with these parameters:
`<project> [roles] <request…>`, tokens from the left.

1. **Project,** required: a path (it has `/` or starts with `~`),
   `~/Code/<name>`, or `.` for the current workspace. A token that does not
   resolve to a directory: list `ls ~/Code`, say it was not found, stop; do
   not pick a project by a similar name.
2. **Roles,** optional: one token of role names joined by `+`, matched
   case-insensitively: `manager`, `architect`, `reviewer`, `tester`, `dev`,
   `auto`, `worker` (`dev+tester`, `reviewer+auto`). It is roles only if
   every part is a role name; otherwise it begins the request.
3. **Request:** the rest, literal. Its first word picks the mode:

| Request | Roles read | Parameters | After the boot |
|---|---|---|---|
| `learn` | BASE, MANAGER | `[--merge \| CAMPAIGN-nnn \| nnn]` | MANAGER §8 (`--merge`: its last paragraph) |
| `review` | BASE, REVIEWER | `TASK-nnn`, or `[--<kind>] [subject…]` | a TASK: REVIEWER §3; a kind (below): its file, then REVIEWER §4 |
| `status` | none | none | no boot: `status.sh`'s output, then the roles loaded in this conversation |
| anything else, with only `dev`, `tester` | each role named, no BASE | the request | no boot: the executor (below) |
| anything else | BASE, then each role named | the request | the request, or wait |

- **Roles and the request:** with no roles, `learn` takes MANAGER, `review`
  REVIEWER, any other request MANAGER. Roles given to `learn` or `review`
  must include its owner: if not, say so and stop. AUTO alone: MANAGER and
  AUTO. WORKER only alone, with BASE, for a request outside the flow. Read
  in this order whatever the order given: BASE, MANAGER, ARCHITECT,
  REVIEWER, TESTER, DEV, AUTO, WORKER. DEV and TESTER taken with a
  coordinator run as executors of the TASK in the request.
- **Status:** takes no roles; if roles are given, say so and stop. Run
  `<bot>/scripts/status.sh <root>` once and answer with its
  output as it is: no reading of the roles or of AGENTS, no boot. Then,
  after the output, a line `roles loaded:` naming each role file read in
  this conversation (BASE, MANAGER, AUTO…), from your own context and not
  from disk; `none` if there is none. Do not reread files to check it.
- **Executor:** with only `dev`, `tester` or `dev+tester` named, the request names a TASK
  (`TASK-nnn` or `nnn`): read `<root>/.bot/tasks/TASK-nnn.md` and follow
  the role files, not this skill's boot. No TASK named, or a TASK whose
  `executor` field is not the roles named: say so and stop.
- **Round:** `CAMPAIGN-nnn#N` in the request is
  `<root>/.bot/campaigns/CAMPAIGN-nnn/round-N.md`.
- **Kind:** `--<kind>` matching a file of `<bot>/roles/reviews/`
  (`--code` is `<bot>/roles/reviews/code.md`); the subject is the
  rest.

## 2. The project
If the project is not the current workspace, read `<root>/AGENTS.md` and,
depending on the active agent, `<root>/CLAUDE.md` (for Claude) or
`<root>/GEMINI.md` (for Gemini) as the project's specific instructions, and
work with absolute paths (`<root>/.bot/`, `git -C <root>`, verification run
from `<root>`).

## 3. Boot
Not for the executor or for `status`. Run `<bot>/scripts/boot.sh <root>`
once; it prints the facts below and does not list `.bot/` (search tools that
honour git's ignore do not see it; list it with `ls`). Read
`<root>/.bot/knowledge/INDEX.md` if the output shows knowledge. Answer
with the boot line (BASE §6).

**In `review` without a TASK or a kind,** list
`ls <bot>/roles/reviews/` and ask which, with the first
sentence of each (`sed -n 3p`); as options when there are four or fewer,
as a numbered list otherwise. Without a subject, ask in the same turn what
is to be reviewed. Then read only the chosen kind's file.
