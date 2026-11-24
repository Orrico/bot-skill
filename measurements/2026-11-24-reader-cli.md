# 2026-11-24 — `READER` on Haiku High vs 3.8 Flash High

Measured which CLI should run the `/bot learn` reader by default: `claude`
with `haiku` (`high`) or `agy` with `gemini-3.8-flash-high`, the two models
`models.md` gives `READER`.

## Method

`delegate.sh <root> reader <folder> <claude|agy> auto`, with the telemetry
of `delegate.sh` (`BOT_TELEMETRY_LOG` pointed outside the projects). Each
model read the same extracts:

1. `tiny`: a throwaway project with an empty knowledge index and one
   two-line extract (one user preference).
2. `A`: the undigested conversations of a Rust project, as
   `learn-sources.sh` extracts them: 2 conversations, 18,298 B.
3. `B`: the same for a static-site project: 2 conversations, 31,831 B.

The `pending` file `learn-sources.sh` writes was removed after each
extraction, so neither harvest ledger changed. Every answer passed
`lessons.jq` (`[]`).

## Data

| Extract | CLI | Time | Input new | Input cached | Output | Thinking | API cost | Candidates |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| `tiny` | `claude` | 8 s | 9,677 | 45,416 | 1,329 | — | $0.003 | 1 |
| `tiny` | `agy` | 161 s | 102,340 | 721,574 | 11,681 | 9,413 | — | 1 |
| `A` | `claude` | 54 s | 35,715 | 113,083 | 12,067 | 10,077 | $0.014 | 5 |
| `A` | `agy` | 208 s | 81,813 | 657,226 | 23,578 | 21,323 | — | 4 |
| `B` | `claude` | 72 s | 42,972 | 69,321 | 16,597 | 14,706 | $0.018 | 5 |
| `B` | `agy` | 348 s | 113,191 | 1,439,726 | 35,762 | 32,882 | — | 1 |

The `tiny` run on `claude` predates the telemetry fix that reads Claude's
thinking tokens.

## Reading

- **Cost:** 3.8 Flash read 5–14× Haiku's input, wrote 2–3× its output
  (mostly thinking) and took 3–20× its time. `agy` reports one turn per
  call and its state is ephemeral in the jail, so where the input went is
  not visible.
- **Yield:** on `A` both found nearly the same lessons. On `B` Haiku found
  five concrete pitfalls and decisions; 3.8 Flash found one, also among
  Haiku's.
- **Quota:** at a project's measured weight of about $0.14 of API price per
  1 % of Claude's five-hour window, a Haiku harvest of this size spends
  about 0.1 % of it.
- **Decision:** the user moved `READER`'s default to `claude`. Three
  samples, two of them real; measure again if a harvest's yield or cost
  departs from these.
