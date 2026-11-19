# Models per tier and CLI

Read by the MANAGER as material when it picks the model of a TASK (BASE §1).
The tiers and the work each one takes are in MANAGER §4; this file holds the
model behind each tier, per CLI or native tool, and the limit of each model.

| Role or tier | `claude` CLI (`--model`) | `agy` CLI (`--model`) | Native Gemini Tool (`Model`) | Limit and use |
|---|---|---|---|---|
| `execution` | `haiku` (Haiku 5.5) | `gemini-4-hydrogen-high` (the cheapest: `gemini-3.8-flash-high`) | `inherit` (if Hydrogen High) / `flash` | Haiku 5.5 and Hydrogen High, one level: a closed, mechanical TASK, its decisions made and its steps given, a critical zone with exact steps among them. Gemini 3.8 Flash, below them: a closed TASK of one module and its tests, about 300 lines, up to 4 files; the tests of the flow itself, and the `READER` in `/bot learn` |
| `review` | `sonnet` (Sonnet 5.5) | `gemini-4-neon-high` | `inherit` (if Neon High) / `pro` | A review by delegation, as the REVIEWER: checks criteria and mutations on delivered TASKs, or runs a review by kind |
| `complex` | `sonnet` (Sonnet 5.5) | `gemini-4-neon-high` | `inherit` (if Neon High) / `pro` | Sonnet 5.5 and Neon High, one level: a TASK of several parts or of reasoning over the existing code; a decision inside a scope already given |
| coordinating roles | `opus` (Opus 5.5) | `gemini-4-argon-high` (fallback: `gemini-4-neon-xhigh`) | `inherit` / `pro` | MANAGER, ARCHITECT, design, decisions, validation; Argon is the strongest of the Gemini models, on a quota of its own and low: `gemini-4-neon-xhigh` when it is tight or exhausted |

- **Opus and Argon are for coordinating roles and for being stuck:** they cost
  more per turn and have tighter quota than Sonnet or Hydrogen. Routine
  work, even a large TASK with the steps given, goes to the tier below them.
- **Quota in `agy`:** Neon, Hydrogen and 3.8 Flash share one bucket;
  Argon has one of its own, and low. Work below the coordinating roles
  goes to the shared bucket, and Argon is kept for coordination and for
  being stuck.
- **Levels across the CLIs (the user, 2026-11-18):** Haiku 5.5 and
  Hydrogen High are one level, Sonnet 5.5 and Neon High the next, and
  Argon above both. Each row of the table pairs a model of each CLI at
  one level.
- **Which mechanism:** within one CLI, its own subagent tool when its model
  options reach the tier's model — the subagent tool in Claude Code,
  `invoke_subagent` in Gemini (below); otherwise `<bot>/scripts/delegate.sh`,
  which crosses CLIs and takes a literal model ID.
- **Native invocation in Gemini (IDE or `agy`):** `invoke_subagent` only
  accepts `inherit`, `flash_lite`, `flash`, or `pro`. Use `inherit` when
  the parent session already runs on the tier's model, and `delegate.sh`
  with the literal ID otherwise; `flash` reaches 3.8 Flash alone. In a
  `swarm`, `add` accepts the literal `agy` model IDs.
- **Delegation via `delegate.sh`:** use the literal CLI model name passed to
  `--model` (`haiku`, `sonnet`, `gemini-3.8-flash-high`,
  `gemini-4-hydrogen-medium`, `gemini-4-hydrogen-high`,
  `gemini-4-hydrogen-xhigh`, `gemini-4-neon-high`, `gemini-4-neon-xhigh`,
  `gemini-4-argon-high`, etc.) when crossing CLIs, or from `agy` when a
  specific Hydrogen or Neon level is needed and `invoke_subagent` cannot
  target it from the current session's model.
