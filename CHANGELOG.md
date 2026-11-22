# Changelog

What changed in the skill, by date, and why. The commits hold the diffs.

## 2026-11-22

- **Calibrated execution and review tiers (`models.md`).** Replaced the two
  execution tiers and single review tier with four execution tiers
  (`trivial`, `standard`, `complex`, `deep`) and three review tiers
  (`review-check`, `review-validate`, `review-deep`), paired across `claude`
  (model + effort) and `agy`, keeping `READER` on `gemini-3.8-flash-high` /
  `haiku` (`high`). `models.md` is now the sole owner of tier criteria,
  `plan:` defaults (`no` for `trivial`/`standard`, `yes` for
  `complex`/`deep`), derived review tiers (raised for critical zones) and
  calibrated escalation (same tier on TASK causes and first `executor`
  send-back; +1 tier only on a second `executor` send-back, anti-loop stop
  or `executor`-caused re-issue, capped at `complex` under AUTO). Updated
  `roles/templates/TASK.md` (`tier:`) and `roles/templates/ROUND.md`
  (`Model` shows `<exec> / <review>`).
- **`task-preflight.sh` frontmatter field checks and `ROUND.md` check #N.**
  Added a `fields:` section to `task-preflight.sh` validating `executor`,
  `tier`, `plan` and `critical_zone` against their allowed sets (catching
  legacy values such as `tier: execution`). Updated `roles/templates/ROUND.md`
  "Lessons" to cite `check #N` of `roles/manager/task.md`.
- **`agy` delegate isolation in `delegate.sh` (`bwrap`).** Masked
  `~/.gemini/config/{skills,plugins,mcp_config.json}` and
  `~/.gemini/antigravity-cli/builtin/{skills,plugins}` read-only empty inside
  the jail: measured −787 input tokens/request (−6.6%) even with 0 MCPs and 0
  plugins installed, and isolates delegates from any ambient MCPs/plugins.
  Added `measurements/tools/fixed-context-agy.sh` and
  `measurements/2026-11-22-agy-lean.md`.
- **`delegate.sh` tier resolution, `-e <effort>` and `agy` lean/JSON output.**
  Added `<model|tier|auto>` resolution straight from `models.md` (deriving
  review tiers from `tier:` + `critical_zone:` or `--<kind>`, with `-n`
  dry-run) and `-e <low|medium|high|xhigh|max>` passed as `--effort` to both
  `claude` and `agy`. `agy` delegates now run with `--disable-slash-commands`
  and `--output-format json`, printing status line and token/turn usage just
  like `claude`.
- **TASK-writing rules read on demand (`roles/manager/task.md`) and
  instruction deduplication.** Moved MANAGER §4's writing rules and 21
  checks into `roles/manager/task.md` so planning, design, validation and
  harvest sessions do not pay for them on every turn. Removed duplicated
  tier tables, delegation prompt wording (kept in BASE §5 alone), output
  trimming in MANAGER §6, and `DEV.md` + `TESTER.md` overlap; moved the
  foreground-command rule once into `DEV.md`, `TESTER.md` and `REVIEWER.md`
  instead of repeating it in every TASK. Added `GEMINI.md` alongside
  `CLAUDE.md` in `DEV.md` and `TESTER.md`, plus anti-loop and concise-output
  rules across `DEV.md`, `TESTER.md` and `REVIEWER.md`.

## 2026-11-19

- **`delegate.sh -w <dir>`,** a directory outside the project that a
  TASK writes in or a review reads, given to the delegate with
  `--add-dir`, and bound into agy's jail with its `.git` read-only. The
  jail hid all of `~/Code` but the project and the skill, so a TASK on a
  theme kept in a repository of its own could not reach its files.
- **The standard files.** `DESIGN.md` holds the data inventory and the flow,
  moved from the README, with the count of each datum and the decisions in
  force; `BACKLOG.md` what is left; this file what changed. The README
  keeps a summary and points to them.
- **The roles beside the MANAGER, by who reads what.** A delegate reviewing a
  TASK reads `REVIEWER.md` alone, which carries the few rules it took from
  BASE: a delegated review measured 254k input tokens before and 181k after,
  in the same turns. Each role's run under AUTO moved to
  `roles/<role>/auto.md`, read only with AUTO. AUTO's commit section keeps
  only what AUTO changes in a role's own rules, which it had repeated and
  contradicted. Which mechanism to delegate by lives in `models.md` alone,
  where four files stated it. BASE dropped its note on file formats no
  project still has; REVIEWER and TESTER stopped describing `mutate.sh`
  from inside; a tip for the user's own session moved to the README.
- **The MANAGER's checks before a TASK goes out** became a numbered list, one
  check per line, "trigger → action". They were two items of 34 and 20
  lines; 37 of 41 classified send-backs were gaps of the TASK, 18 of them
  `tests`. The file came out smaller.
- **Measurements.** `measurements/` holds what was measured about the skill
  and the tools to measure it again: closed rounds, send-back causes, the
  fixed context of a delegate, the prose a model reads.
- **A lean delegate.** A `claude` delegate runs with the tools of a role's
  work alone, without MCP or skills: its fixed context fell from 27.7k to
  15.9k tokens. `delegate.sh` prints each delegation's tokens and cost.
  `--bare` would cut more but does not read the subscription's login.
- **`new.sh`** creates a campaign, round, TASK or review from its template,
  at the next number, with what is known filled; `task-preflight.sh` lists
  what is left unfilled. A model filled the whole form by hand before.
- **`round-close.sh`** checks a round before it closes: each row closed,
  each done row's TASK validated and its commit in git, each send-back with
  a cause of the set. An audit of 112 closed rounds found 3 closed with a
  row open and a TASK past the send-back limit.
- **The send-back limit** stays 2 in the prose; 3 to 5 only on the user's
  word, never under AUTO; `delegate.sh` refuses the 6th. A TASK once
  needed 3, the work being right.
- **README:** told by its data — the inventory, the flow, what each role
  and script reads and writes — with a prompt to paste into an agent to
  install the skill.
- **Code review** reads each component against the project's stated bar;
  a UI TASK with no tests asserts on the compiled output.
- **Models** paired across CLIs by level: Haiku 5.5 with Hydrogen High,
  Sonnet 5.5 with Neon High, Argon above both.
- **`agy`'s jail** gets a writable `XDG_CACHE_HOME`: nix writes its caches
  there, and `~/.cache` is read-only inside.

## 2026-11-13

- Model assignments and the delegation docs updated.

## 2026-11-11

- Model roles updated; the MANAGER's rules on execution refined.

## 2026-11-10

- The executor breaks each condition it adds and adds the test a surviving
  one lacks; a TASK is checked against the tree before it goes out; three
  rules stop asking the user.
- A TASK gives its data as the code has it, from `file:line`; a send-back's
  cause is one word of a closed set.

## 2026-11-09

- Data-oriented design in the ARCHITECT and the design review: a data
  inventory with the source of each fact, and the flow of the data beside
  it, checked against each other.
- The MANAGER slimmed for long campaign sessions: the harvest and the run
  under AUTO read on demand, command output trimmed, the context cleared at
  a round's close.
- The MANAGER validates from the review of each delivered TASK; the
  mutation procedure moved to the REVIEWER.
- Guidance on model use and on saving context, from Anthropic's Claude
  Code guides.

## 2026-11-05

- `/bot`: a skill that takes roles on a project, self-contained — its
  roles, templates, review kinds and scripts in one folder.
- `AGENTS.md`: how to work on the skill — the roles' rules, conventions,
  pitfalls and verification.
- The skill's description quoted: its colon broke the YAML frontmatter.
