# Models per tier and CLI

Read by the MANAGER as material when it picks the model of a TASK (BASE §1).
The tiers and the work each one takes are in MANAGER §4; this file holds the
model behind each tier, per CLI or native tool, and the limit of each model.

| Role or tier | `claude` CLI (`--model`) | `agy` CLI (`--model`) | Native Gemini Tool (`Model`) | Limit and use |
|---|---|---|---|---|
| `execution`, the cheapest | `haiku` (Haiku 5.5) | `gemini-3.8-flash-high` | `flash` | Gemini 3.8 / Flash: a closed TASK of one module and its tests, about 300 lines, up to 4 files; with `plan: yes`, one of several closed steps. The cheapest: tests of the flow itself run on it. Haiku 5.5: a closed, mechanical TASK larger than the 3.8's limit, or a critical zone with exact steps |
| `complex` | `sonnet` (Sonnet 5.5) | `gemini-4-argon-medium` | `pro` | A TASK of several parts or of reasoning over the existing code; a decision inside a scope already given |
| `review` | `sonnet` (Sonnet 5.5) | `gemini-3.8-flash-high` | `flash` | A review by delegation, as the REVIEWER: checks criteria and mutations on delivered TASKs |
| coordinating roles | `opus` (Opus 5.5) | `gemini-4-argon-high` | `inherit` / `pro` | MANAGER, ARCHITECT, design, decisions, validation |

- **Opus is for the coordinating roles and for being stuck:** it costs
  several times more per turn than Sonnet. Routine work, even a large TASK
  with the steps given, goes to the tier below it.
- **In Claude Code, plan with Opus and execute with Sonnet:** `/model
  opusplan` does it in one session, and switching models keeps the
  conversation.
- **Native invocation in Gemini (IDE or `agy`):** use `invoke_subagent` with
  the value from the `Native Gemini Tool` column (`flash`, `pro`, `inherit`).
- **Cross-CLI delegation via `delegate.sh`:** use the literal CLI model name
  passed to `--model` (`haiku`, `gemini-3.8-flash-high`, `gemini-4-argon-medium`,
  `gemini-4-argon-high`, etc.).
- A MANAGER on Gemini does not call `delegate.sh` for Gemini models; it uses
  the native tool.
