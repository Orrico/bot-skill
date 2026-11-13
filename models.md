# Models per tier and CLI

Read by the MANAGER as material when it picks the model of a TASK (BASE §1).
The tiers and the work each one takes are in MANAGER §4; this file holds the
model behind each tier, per CLI or native tool, and the limit of each model.

| Role or tier | `claude` CLI (`--model`) | `agy` CLI (`--model`) | Native Gemini Tool (`Model`) | Limit and use |
|---|---|---|---|---|
| `execution`, the cheapest | `haiku` (Haiku 5.5) | `gemini-3.8-flash-high` | `flash` | Gemini 3.8 / Flash: a closed TASK of one module and its tests, about 300 lines, up to 4 files; with `plan: yes`, one of several closed steps. The cheapest: tests of the flow itself, and the `READER` in `/bot learn`, run on it. Haiku 5.5: a closed, mechanical TASK larger than the 3.8's limit, or a critical zone with exact steps |
| `review` | `sonnet` (Sonnet 5.5) | `gemini-4-hydrogen-medium` | `inherit` (if Hydrogen) / `flash` | A review by delegation, as the REVIEWER: checks criteria and mutations on delivered TASKs, or runs a review by kind |
| `complex` | `sonnet` (Sonnet 5.5) | `gemini-4-hydrogen-high` | `inherit` (if Hydrogen High/XHigh) / `pro` | A TASK of several parts or of reasoning over the existing code; a decision inside a scope already given |
| coordinating roles | `opus` (Opus 5.5) | `gemini-4-argon-high` (fallback: `gemini-4-hydrogen-xhigh`) | `inherit` / `pro` | MANAGER, ARCHITECT, design, decisions, validation; use `gemini-4-hydrogen-xhigh` when Argon quota is tight or exhausted |

- **Opus and Argon are for coordinating roles and for being stuck:** they cost
  more per turn and have tighter quota than Sonnet or Hydrogen. Routine
  work, even a large TASK with the steps given, goes to the tier below them.
- **In Claude Code, plan with Opus and execute with Sonnet/Haiku:** `/model
  opusplan` does it in one session, and switching models keeps the
  conversation.
- **Hydrogen vs. Argon quota in `agy`:** `gemini-4-hydrogen-*` (`low`,
  `medium`, `high`, `xhigh`) shares its quota bucket with
  `gemini-3.8-flash-*`, separate from `gemini-4-argon-*`. Delegating
  `review` to `gemini-4-hydrogen-medium` and `complex` to
  `gemini-4-hydrogen-high` preserves Argon quota for coordination.
- **Native invocation in Gemini (IDE or `agy`):** `invoke_subagent` only
  accepts `inherit`, `flash_lite`, `flash`, or `pro`. Use `flash` for
  `execution`, and `inherit` when the parent session already runs on the
  tier's model. In a `swarm`, `add` accepts the literal `agy` model IDs.
- **Delegation via `delegate.sh`:** use the literal CLI model name passed to
  `--model` (`haiku`, `sonnet`, `gemini-3.8-flash-high`,
  `gemini-4-hydrogen-medium`, `gemini-4-hydrogen-high`,
  `gemini-4-hydrogen-xhigh`, `gemini-4-argon-high`, etc.) when crossing CLIs,
  or from `agy` when a specific Hydrogen level is needed and `invoke_subagent`
  cannot target it from the current session's model.
