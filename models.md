# Models per tier and CLI

Single source of truth for tiers, model pairings, defaults, escalation and
delegation mechanisms. Read by the MANAGER on demand when planning a round,
writing a TASK or handing one over (BASE §1).

## Execution tiers

Ordered from weakest to strongest. `Plan` is the default for the TASK's `plan:`
field; `Review` is the default review tier when `critical_zone: no` (a critical
zone raises `review-check` to `review-validate`).

| Tier | `claude` (`--model`, `--effort`) | `agy` (`--model`) | Plan | Review | Use |
|---|---|---|---|---|---|
| `standard` | `sonnet`, `medium` | `gemini-4-hydrogen-medium` | `no` | `review-check` | A closed TASK (one crate, one code path), or a critical zone with exact steps: decisions already made, criteria verifiable by command |
| `complex` | `sonnet`, `high` | `gemini-4-hydrogen-high` | `yes` | `review-validate` | Several parts or reasoning over existing code; concurrent logic; a decision inside a scope already given |
| `deep` | `opus`, `high` | `gemini-4-neon-high` | `yes` | `review-deep` | High-risk refactor, open critical zone, or escalation when stuck |

Design and a pending decision never go to an execution tier; design, decisions
and validation stay with the coordinating roles. A TASK larger than the limit of
its model is split into a sequence of TASKs, each on the validated code of the
one before.

## Review tiers

| Tier | `claude` (`--model`, `--effort`) | `agy` (`--model`) | Use |
|---|---|---|---|
| `review-check` | `sonnet`, `medium` | `gemini-4-hydrogen-medium` | Default for `standard` deliveries outside a critical zone: diff vs Files, criteria, mutations |
| `review-validate` | `sonnet`, `high` | `gemini-4-hydrogen-high` | Default for `complex` deliveries, critical zones, and reviews by kind (`--code`, `--editorial`, `--market`) |
| `review-deep` | `opus`, `high` | `gemini-4-neon-high` | `deep` deliveries, `--design`, invariant or security audits, or tie-break after a failure |

The review tier is derived from the TASK's `tier` and `critical_zone` by default
and overridden only when the risk asks for it. In a round's `Plan`, the `Model`
column states both (`<exec> / <review>`), so confirming the round approves both
delegations (BASE §5).

## Other roles

| Role | `claude` (`--model`, `--effort`) | `agy` (`--model`) | Use |
|---|---|---|---|
| `READER` | `haiku`, `high` | `gemini-3.8-flash-high` | Conversation extraction into closed JSON in `/bot learn` |
| coordinating roles | `opus`, `high` | `gemini-4-neon-high` | MANAGER, ARCHITECT, design, decisions, validation |

## Escalation on send-back and re-issue

- **TASK causes** (`tests`, `data`, `untried`, `dependents`, `rule`): keep the
  **same tier** — the gap was in the specification, not in model capacity.
- **First `executor` send-back** (a missed check or narrow slip): keep the
  **same tier** — the gap is now explicit, which saves quota and keeps the retry
  focused.
- **Escalate one tier** (`standard` → `complex` → `deep`) only on:
  a second `executor`-caused send-back on the same TASK, an executor stopping
  on the anti-loop rule or complexity limit, or a re-issue after a rejection
  caused by `executor`. Under AUTO, automatic escalation stops at `complex`;
  escalating to `deep` requires the user.

## Quota and mechanisms

- **Tier policy:** across both CLIs, Opus High and Neon High coordinate and
  take `deep` and `review-deep`; Sonnet High and Hydrogen High take `complex`
  and `review-validate`; Sonnet Medium and Hydrogen Medium take `standard` and
  `review-check`; `READER` stays on Haiku High and 3.8 Flash High. No effort
  past `high` (`max` and `xhigh` spend Claude quota fast), and Argon is not
  used. In `agy`, Neon, Hydrogen, 3.8 Flash and Argon share one rolling
  five-hour and one rolling weekly quota; new context and output dominate cost,
  not cached input.
- **`deep`** is for genuinely high-risk work or escalation after failure,
  not routine multi-file TASKs with exact steps.
- **Single mechanism — `<bot>/scripts/delegate.sh`:** all delegations (TASK
  execution, TASK review, review by kind, and `READER`) run through
  `delegate.sh`, not native subagent tools (`invoke_subagent` or Claude's Agent
  tool). Native subagent aliases drift across CLI releases (e.g. Gemini's
  `flash` resolves to Hydrogen rather than 3.8 Flash), inherit ambient skills
  and MCPs, and bypass structured telemetry logging.
- **Using `delegate.sh`:** pass `auto` (resolves the model and effort from this
  file using the TASK's `tier:` and `critical_zone:`, the review kind, or
  `READER`), a tier name from the tables above (to override or escalate), or a
  literal CLI model ID with `-e <low|medium|high|xhigh|max>` when needed. `-n`
  prints the resolved model without running. Every non-dry-run call appends one
  JSONL telemetry row to `<root>/.bot/delegations.jsonl` (overridable via
  `BOT_TELEMETRY_LOG`).
