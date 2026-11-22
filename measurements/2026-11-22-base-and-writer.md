# 2026-11-22 — `BASE.md` concision pass and `WRITER.md` generalization

Tightened `roles/BASE.md` across §1–§6 (preserving every rule, portability and
all section numbers, turning the five root standard files in §4 into a table),
and replaced project-specific Portuguese Astro rules in `roles/WRITER.md` with
project-agnostic English editorial rules (wrapped at 80 columns) while wiring
`executor: writer` through `new.sh`, `delegate.sh`, `task-preflight.sh` and
`SKILL.md`.

## The prose

**Method:** `tools/prose.sh <bot>`, before (`6cacd5f` / `90f3b64`) and after;
tokens are `bytes / 4`.

| File | Before | After | Delta | Notes |
|---|---:|---:|---:|---|
| `roles/BASE.md` | 3,439 | 2,285 | −1,154 (−33.6%) | sentences > 40 words: 7 → 2; words/s: 19 → 17 |
| `roles/WRITER.md` | 1,076 | 865 | −211 (−19.6%) | 16 lines > 80 cols → 0; 0 violations in `roles/` |
| `BASE` + `MANAGER` (no TASK write) | 8,641 | 5,569 | −3,072 (−35.6%) | total drop across today's session (vs `a658a05`) |

## Reading

- `roles/BASE.md` is loaded on every turn of every coordinating role (`MANAGER`,
  `ARCHITECT`, `REVIEWER` interactive/by-kind, `AUTO`, `WORKER`). Saving 1,154
  prose tokens removes roughly 2.3k context tokens per request (at the ~2×
  `Read` framing ratio measured in `2026-11-19-roles-review.md`).
- Across today's changes, a coordinating `MANAGER` session that does not write
  a TASK loads **3,072 fewer prose tokens** (−35.6%) on every turn, with zero
  80-column prose violations remaining anywhere in `roles/`.

## To measure again

Compare real coordinating sessions (`MANAGER` / `MANAGER+ARCHITECT`) in
`tools/delegate-usage.sh` or session transcripts against pre-2026-11-22 runs,
and watch for any misread rule in `BASE.md` during harvests (`/bot learn`).
