# Changelog

What changed in the skill, by date, and why. The commits hold the diffs.

## 2026-11-24

- **Claude `standard` and `review-check` moved to Sonnet Medium; all
  delegations standardized on `delegate.sh`.** Across calibration rounds,
  Sonnet Medium ran `standard` TASKs 5–10× faster and 2.5–4.7× cheaper than
  Haiku High, caught specification contradictions cleanly, and reviewed in
  under 90 s; `READER` stays on `haiku` (`high`) / `gemini-3.8-flash-high`.
  Removed the `Native Gemini (Model)` column from `models.md` because
  Gemini's `flash` subagent alias drifted to Hydrogen; all execution, review
  and `READER` calls now run through `scripts/delegate.sh`.
- **`delegate.sh`: `reader` mode and structured JSONL telemetry.** Added
  `delegate.sh <root> reader <folder> <claude|agy> auto` (resolving `READER`
  from `models.md`, mounting `<root>` read-only and `<folder>` writable
  under `agy`'s `bwrap` jail, and checking `<folder>/candidates.json`). Every
  non-dry-run call now appends a structured JSONL record (timestamp, mode,
  target, send-back count, CLI, tier, model, effort, exit code, duration,
  tokens, API cost, result status) to `<root>/.bot/delegations.jsonl`
  (overridable via `BOT_TELEMETRY_LOG`).
- **Send-back authorization visible to reviewers.** `roles/DEV.md`,
  `roles/TESTER.md`, `roles/WRITER.md` and `delegate.sh -g` now require each
  `## Send-back N` section to begin with `Gap: <verbatim gap received>` so a
  reviewer evaluating a post-send-back delivery can verify authorized
  departures from the frozen TASK.
- **`mutate.sh` fast-fail on unsplit commands.** Added a `command -v "$1"`
  pre-check before mutating the target file, exiting 2 with a hint when the
  test command is passed as one quoted string or an unsplit zsh `$VAR`.
- **Pre-handover and harvest checks tightened.** `roles/manager/task.md`
  adds shared test helper modules (`tests/common/mod.rs`) to Check 1, exact
  proving calls for hidden fields to Check 5, and producer checks for refusal
  codes and query/stream filters in `src/` to Check 14.
  `roles/manager/learn.md` uses `delegate.sh reader` and forbids recording
  unmeasured inferences or undecided choices as guidance in `.bot/knowledge/`.
- **Gaps of the same day's changes closed.** `delegate.sh reader` takes
  `-g` with `lessons.jq`'s errors, since `learn.md` sends a failed
  `candidates.json` back to the reader with them and the fixed prompt
  could not carry them. `REVIEWER.md` checks each `## Send-back N` against
  its `Gap:` line, which the executors wrote and no reviewer read. The
  wording tied to one language goes: `standard` is one code path in one
  file or several (not "one crate"), Check 14 reads the code that produces
  the text (not `src/`), and Check 1's helper module is Rust's example.
  The models leave DESIGN.md and `learn.md`, which repeated `models.md`.
  `BASE.md` commits the rows `delegations.jsonl` gains with each `.bot/`
  step, which no step committed.

## 2026-11-23

- **The tiers chosen by the user, and `trivial` gone.** Three execution
  tiers: `standard` on Haiku High and Hydrogen Medium (the old `trivial`
  folded into it), `complex` on Sonnet High and Hydrogen High, `deep` on
  Opus High and Neon High; the review tiers pair the same way
  (`review-check`, `review-validate`, `review-deep`), and the
  coordinating roles stay on Opus High and Neon High. No effort past
  `high`, since `max` spends a Claude quota fast; Argon leaves the
  tables, the Gemini model that spent the most tokens for the least.
  Hydrogen High moves up a tier: arena.ai's Agent Arena of 2026-11-22
  ranks it beside Opus High (1,272 and 1,275), above Sonnet High
  (1,202), and Neon High above both (1,331). `models.md`'s quota
  section says agy's models now share one week's and one five hours'
  quota, its measured weights ratios only. `delegate.sh`,
  `task-preflight.sh`, `roles/templates/TASK.md`, `roles/MANAGER.md`,
  `roles/manager/task.md` and DESIGN.md name the three tiers.
- **The code bar reaches the executor and the review.** `roles/DEV.md`
  reads the bar the project's `AGENTS.md` names before the first edit,
  and carries the checkable rules itself — one place for each rule, data
  in the shape of its access, no function that names one step of its
  caller, no option for a case that does not exist, no redundant check,
  whole names, errors that keep their cause — and doc comments of
  contract, never paraphrase; `roles/TESTER.md` holds test code to the
  same bar. `roles/REVIEWER.md` §3 step 5 reads the diff against it: a
  rule missed is a finding, a preference no rule states a note, since a
  reviewer asked for problems always finds one.
- **Two pre-handover checks from CAMPAIGN-020 round 19 of ARC.** Check 4
  of `roles/manager/task.md`: a setting, a hook or a service a test turns
  on for the first time in its file is run there on the real tool before
  the handover — a test that first set a bound ran a hook no test had run,
  and it refused every push. Check 15: the table of conditions of a TASK
  with no prototype has one row for each branch, two rows sharing a test
  only where it drives both — a row "steps 5 and 7" had one test, which
  drove step 7 alone.

## 2026-11-22

- **`delegate.sh`: agy's `bin` writable in the jail, and one `usage:`
  line for both CLIs.** The jail mounted agy's state on a tmpfs and bound
  `bin` back read-only, but agy rewrites `bin/agentapi` on each command,
  so every `run_command` failed with `read-only file system` and a
  delegate came back blocked in seconds; `bin` is now bound writable, the
  other three entries still read-only. The `usage:` line printed
  Claude's input with its cache and agy's without it, so the two did not
  compare; both now print the total, then the new and the cached parts:
  `usage: <total> tokens in (<new> new, <cached> from cache); …`.
- **Pre-handover checks, self-contained send-backs and `mutate.sh` build
  detection.** `scripts/mutate.sh` now detects Rust/TypeScript compilation
  errors (`could not compile`, `error[E…]`, `error TS…`) and exits `2`
  (`INVALID`) instead of counting uncompilable mutations as killed.
  `roles/manager/task.md` sharpens checks #4, #5 and #15 (manifest/tool
  range checks, every branch/fallback/`serde` attribute tested or marked
  judged, mutations run against TASK cases before handover) and adds a
  pre-handover review rule for code dictated whole; `roles/MANAGER.md` §6
  requires send-back gaps to be written whole without citing earlier
  prompts; `BACKLOG.md` tracks session resume on `delegate.sh -g`.
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
- **Concision pass on `roles/BASE.md`.** Tightened prose across §1–§6 and
  turned §4's five standard files into a table without dropping rules or
  renumbering sections: `BASE.md` fell from 3,439 to 2,285 tokens (−33.6%,
  sentences > 40 words 7 → 2), recorded in
  `measurements/2026-11-22-base-and-writer.md`.
- **Generalized `roles/WRITER.md` and wired `writer` into the scripts.**
  Replaced project-specific Portuguese Astro rules in `WRITER.md` with
  project-agnostic editorial rules in English (wrapped at 80 columns,
  deferring style/schema rules to each project's `EDITORIAL.md`, with
  `GEMINI.md`, foreground, anti-loop and concise-output rules). Added
  `executor: writer` support to `new.sh`, `delegate.sh`,
  `task-preflight.sh`, `SKILL.md`, `roles/templates/TASK.md`,
  `roles/templates/ROUND.md`, `MANAGER.md`, `roles/manager/task.md` and
  `REVIEWER.md`.
- **SQLite WAL isolation for `agy` delegates and read-only harvest queries.**
  `conversation_summaries.db` runs in WAL mode: `delegate.sh` previously
  bound `~/.gemini/antigravity-cli` writable while replacing only the `.db`
  file, letting jailed delegates write mismatched `-wal`/`-shm` sidecars on
  the host (causing `database disk image is malformed (11)`). Replaced that
  with an ephemeral `--tmpfs` over `$agy_state` (binding only `bin`,
  `builtin`, `installation_id` and `settings.json` read-only), and switched
  `learn-sources.sh` to `sqlite3 -readonly -cmd ".timeout 5000"` with an
  explicit warning on query failure.
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
