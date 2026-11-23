# Models per tier and CLI

Single source of truth for tiers, model pairings, defaults, escalation and
delegation mechanisms. Read by the MANAGER on demand when planning a round,
writing a TASK or handing one over (BASE §1).

## Execution tiers

Ordered from weakest to strongest. `Plan` is the default for the TASK's `plan:`
field; `Review` is the default review tier when `critical_zone: no` (a critical
zone raises `review-check` to `review-validate`).

| Tier | `claude` (`--model`, `--effort`) | `agy` (`--model`) | Native Gemini (`Model`) | Plan | Review | Use |
|---|---|---|---|---|---|---|
| `trivial` | `haiku`, `high` | `gemini-4-hydrogen-medium` | `inherit` (if Hydrogen Medium) | `no` | `review-check` | 1–4 files, closed mechanical change, single module and its tests (~300 lines) |
| `standard` | `sonnet`, `medium` | `gemini-4-hydrogen-high` | `inherit` (if Hydrogen High) | `no` | `review-check` | Closed TASK across several files, or a critical zone with exact steps, decisions already made, criteria verifiable by command |
| `complex` | `sonnet`, `high` | `gemini-4-neon-medium` | `inherit` (if Neon Medium) | `yes` | `review-validate` | Several parts or reasoning over existing code; a decision inside a scope already given |
| `deep` | `opus`, `max` | `gemini-4-neon-xhigh` | `inherit` (if Neon XHigh) | `yes` | `review-deep` | High-risk refactor, open critical zone, or escalation when stuck |

Design and a pending decision never go to an execution tier; design, decisions
and validation stay with the coordinating roles. A TASK larger than the limit of
its model is split into a sequence of TASKs, each on the validated code of the
one before.

## Review tiers

| Tier | `claude` (`--model`, `--effort`) | `agy` (`--model`) | Native Gemini (`Model`) | Use |
|---|---|---|---|---|
| `review-check` | `haiku`, `high` | `gemini-4-hydrogen-medium` | `inherit` (if Hydrogen Medium) | Default for `trivial` and `standard` deliveries outside a critical zone: diff vs Files, criteria, mutations |
| `review-validate` | `sonnet`, `high` | `gemini-4-neon-medium` | `inherit` (if Neon Medium) | Default for `complex` deliveries, critical zones, and reviews by kind (`--code`, `--editorial`, `--market`) |
| `review-deep` | `opus`, `high` | `gemini-4-argon-high` (fallback: `gemini-4-neon-high`) | `inherit` / `pro` | `deep` deliveries, `--design`, invariant or security audits, or tie-break after a failure |

The review tier is derived from the TASK's `tier` and `critical_zone` by default
and overridden only when the risk asks for it. In a round's `Plan`, the `Model`
column states both (`<exec> / <review>`), so confirming the round approves both
delegations (BASE §5).

## Other roles

| Role | `claude` (`--model`, `--effort`) | `agy` (`--model`) | Native Gemini (`Model`) | Use |
|---|---|---|---|---|
| `READER` | `haiku`, `high` | `gemini-3.8-flash-high` | `flash` | Conversation extraction into closed JSON in `/bot learn` |
| coordinating roles | `opus`, `high` | `gemini-4-neon-high` | `inherit` / `pro` | MANAGER, ARCHITECT, design, decisions, validation |

## Escalation on send-back and re-issue

- **TASK causes** (`tests`, `data`, `untried`, `dependents`, `rule`): keep the
  **same tier** — the gap was in the specification, not in model capacity.
- **First `executor` send-back** (a missed check or narrow slip): keep the
  **same tier** — the gap is now explicit, which saves quota and preserves
  interactive context when handed over by the user (`delegate.sh` starts a
  fresh headless session on every call).
- **Escalate one tier** (`trivial` → `standard` → `complex` → `deep`) only on:
  a second `executor`-caused send-back on the same TASK, an executor stopping
  on the anti-loop rule or complexity limit, or a re-issue after a rejection
  caused by `executor`. Under AUTO, automatic escalation stops at `complex`;
  escalating to `deep` requires the user.

## Quota and mechanisms

- **Quota in `agy`:** Neon, Hydrogen and 3.8 Flash share one bucket; Argon has
  its own small bucket. Keep Argon for `review-deep` (falling back to
  `gemini-4-neon-high` when tight or exhausted) and for being stuck.
  Measured on the shared bucket's five hours' window (2026-11-23): Neon
  Medium about 11.6 points per million tokens not cached (new input and
  output alike) and 0.86 per million cached; Hydrogen about half of
  Neon's for the same tokens. What costs is new context and output, not
  the cache. Both windows, the week's and the five hours', roll.
  So a `standard` TASK outside a critical zone, closed and simple, may
  take `gemini-4-hydrogen-medium` by its literal ID; the table's Hydrogen
  High, which `auto` resolves, stays for the rest.
- **Opus `max` and Neon `xhigh`:** reserve `deep` for genuinely high-risk work
  or escalation after failure, not routine multi-file TASKs with exact steps.
- **Which mechanism:** within one CLI, its own subagent tool when its model
  options reach the tier's exact model and effort — the subagent tool in Claude
  Code, `invoke_subagent` in Gemini (below); otherwise
  `<bot>/scripts/delegate.sh`, which crosses CLIs and takes a literal model ID
  plus `-e <effort>`.
- **Native invocation in Gemini (IDE or `agy`):** `invoke_subagent` only
  accepts `inherit`, `flash_lite`, `flash`, or `pro`. Use `inherit` when the
  parent session already runs on the tier's model, `flash` for `READER`
  (3.8 Flash), and `delegate.sh` with the literal ID otherwise. In a `swarm`,
  `add` accepts literal `agy` model IDs.
- **Delegation via `delegate.sh`:** pass `auto` (resolves the model and effort
  from this file using the TASK's `tier:` and `critical_zone:`, or the review
  kind), a tier name from the tables above (to override or escalate), or a
  literal CLI model ID with `-e <low|medium|high|xhigh|max>` when needed. `-n`
  prints the resolved model without running.
