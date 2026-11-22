# 2026-11-22 — calibrated model tiers, lean `agy` and instruction deduplication

Replaced two execution tiers and one review tier with four execution tiers
(`trivial`, `standard`, `complex`, `deep`) and three review tiers
(`review-check`, `review-validate`, `review-deep`), added `-e <effort>` and
lean/JSON output for `agy` in `delegate.sh`, moved TASK-writing rules and the
21 checks out of `MANAGER.md` into `roles/manager/task.md` (on demand),
removed cross-file repetitions and added foreground-command, anti-loop and
concise-output rules to executors and reviewers.

## 1. CLI probes (`claude --effort` and `agy --output-format json`)

**Question:** Does `claude` accept `--effort high` on `haiku`, and does `agy`
emit token and turn telemetry with `--disable-slash-commands --output-format
json`?

**Method:** one-word headless calls on this machine (`2026-11-22`):

```
claude -p "reply with ok" --model haiku --effort high --tools "" --strict-mcp-config --disable-slash-commands --output-format json
agy -p "reply with ok" --model gemini-3.8-flash-high --disable-slash-commands --output-format json --settings '{"agentMode":"","enableTerminalSandbox":false}'
```

**Data:**
- `claude`: exited 0 (`is_error: false`), ran `claude-haiku-5-5`, 1 turn,
  `inputTokens: 2`, `cacheReadInputTokens: 649`, `cacheCreationInputTokens:
  7421`, `outputTokens: 4`, `$0.00149`.
- `agy`: exited 0 (`status: "SUCCESS"`), 1 turn, `duration_seconds: 3.95`,
  `usage: {input_tokens: 11928, output_tokens: 148, thinking_tokens: 147,
  cache_read_tokens: 0, total_tokens: 12076}`.

**Reading:** both CLIs accept `--effort <low|medium|high|xhigh|max>` and emit
structured JSON with per-session token and turn counts. `delegate.sh` now
passes `-e <effort>` to both, runs `agy` with `--disable-slash-commands` and
`--output-format json`, and prints a uniform `usage:` line for both CLIs.

## 2. The prose a model reads

**Method:** `tools/prose.sh <bot>`, before (at `a658a05` + `439994c`) and after;
tokens are `bytes / 4`.

| File | Before | After | Delta | Notes |
|---|---:|---:|---:|---|
| `roles/MANAGER.md` | 5,196 | 3,282 | −1,914 (−37%) | sentences > 40 words: 11 → 5 |
| `roles/manager/task.md` | — | 1,673 | +1,673 | new; read on demand when writing a TASK |
| `MANAGER` + `task.md` combined | 5,196 | 4,955 | −241 (−5%) | smaller even in sessions that write TASKs |
| `roles/BASE.md` | 3,445 | 3,439 | −6 | round approval names exec + review models |
| `roles/AUTO.md` | 1,241 | 1,223 | −18 | dropped repeated delegation prompt rule |
| `roles/manager/auto.md` | 751 | 764 | +13 | caps automatic escalation at `complex` |
| `roles/DEV.md` | 1,249 | 1,322 | +73 | added `GEMINI.md`, foreground, anti-loop, concise result |
| `roles/TESTER.md` | 1,325 | 1,230 | −95 | trimmed overlap with `DEV.md`, added `GEMINI.md`, anti-loop |
| `DEV` + `TESTER` combined | 2,574 | 2,552 | −22 | net smaller with new safety/anti-loop rules |
| `roles/REVIEWER.md` | 1,880 | 1,964 | +84 | added foreground, anti-loop, concise review |
| `models.md` | 843 | 1,296 | +453 | sole owner of 4 exec + 3 review tiers, defaults, escalation (on demand) |
| `roles/templates/TASK.md` | 438 | 442 | +4 | 4 execution tiers in `tier:` |
| `roles/templates/ROUND.md` | 580 | 583 | +3 | `<exec> / <review>` in `Model` |

**Reading:**
- Sessions that do not write a TASK (planning, design with ARCHITECT,
  validation, round close, `/bot learn`) save **1,914 tokens** of prose (~3.8k
  context tokens per request via `Read`, by the 2× ratio measured in
  `2026-11-19-roles-review.md`) on every turn.
- Even sessions that *do* write TASKs pay 241 fewer tokens in `MANAGER` +
  `task.md` than before, while `models.md` (read on demand) holds the full
  tier/escalation table without duplicating it in `MANAGER.md`.
- `DEV.md` + `TESTER.md` combined (`dev+tester`, the most common executor) is
  22 tokens smaller despite gaining the foreground-command rule (previously
  repeated in every TASK), anti-loop stop rule, concise-output rule and
  `GEMINI.md`.

## To measure again

1. Compare real `delegate.sh` runs on `agy` (with the new `usage:` line) and
   `claude` across the new tiers (`trivial`/`review-check` vs
   `standard`/`review-validate`) against the baseline's 17–40 turn executor
   runs and 181k-token reviews.
2. Track whether the anti-loop rule caps runaway executor sessions (baseline
   peak: 40 requests, 5.8M input tokens) and whether `executor`-caused
   send-backs stay low under `trivial` and `standard`.
