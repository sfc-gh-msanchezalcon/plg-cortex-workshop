# Architecture

The workshop builds four layers. The key idea is the split between what is
**cached** (computed once per row) and what is **live** (computed per question).

```
                         ┌──────────────────────────────────────────┐
                         │  Layer 1 — Foundation                     │
  SURVEY_RESPONSES  ─┐   │  SURVEY_BASE (view, 1 row per response)    │
  GAME_ROUNDS       ─┼──▶│  SURVEY_ANALYSIS (semantic view)          │
  PLAYER_BEHAVIOUR  ─┘   │     dims + metrics, NL-queryable           │
                         └───────────────┬──────────────────────────┘
                                         │
                         ┌───────────────▼──────────────────────────┐
                         │  Layer 2 — Core AI  (CACHED / precompute) │
                         │  SURVEY_ENRICHED (Dynamic Table, from       │
                         │   SURVEY_BASE, deterministic pre-filter):   │
                         │     AI_FILTER   → is_substantive            │
                         │     AI_SENTIMENT→ clarity/tone sentiment    │
                         │     AI_CLASSIFY → clarity_topic             │
                         │  incremental: reruns only on new rows       │
                         └───────────────┬──────────────────────────┘
                                         │
              ┌──────────────────────────┼───────────────────────────┐
              │                          │                           │
  ┌───────────▼──────────┐   ┌───────────▼──────────┐    ┌───────────▼─────────┐
  │ Layer 3 — Advanced   │   │ Layer 4 — Consumption │    │  LIVE (per question) │
  │ Cortex Search        │   │ Cortex Agent          │    │  AI_AGG /            │
  │ (retrieval, stretch) │   │ Analyst + Search +    │    │  AI_SUMMARIZE_AGG    │
  │                      │   │ summarize; verified   │    │  the "why" answers   │
  │                      │   │ queries; evaluation   │    │                      │
  └──────────────────────┘   └───────────────────────┘    └─────────────────────┘
```

## Cached vs live — the whole cost story

| | What | When it runs | Why |
|---|---|---|---|
| **Cached** | sentiment, topic (and embeddings, via Search) | once per row, incrementally | stable per row → materialise and reuse everywhere |
| **Live** | summaries, "explain the driver", synthesis | per question | depends on *which rows* and *what to highlight* → can't precompute |

This is the correction to the current prototype: it called `SUMMARIZE`/`COMPLETE`
live for *everything*, which is why batching/truncation were needed. Move the
stable per-row work to the cached layer and the live layer becomes cheap and small.

## Why a Dynamic Table for the enrichment
- AI functions sit in the `SELECT`, so an **incremental** refresh only invokes the
  model on **new/changed rows** — not the whole history every time.
- **Incremental rule:** Cortex AI functions are incremental-safe **only in the
  SELECT clause**, never in `WHERE`. So the table reads from `SURVEY_BASE` with a
  cheap *deterministic* pre-filter (`LENGTH(TRIM(...)) > 4`), and `AI_FILTER`
  becomes an `is_substantive` **column** rather than a WHERE predicate. (Putting
  `AI_FILTER` in a WHERE — e.g. via the ad-hoc `SURVEY_CLEAN` view — forces a FULL
  refresh; set `REFRESH_MODE = INCREMENTAL` to catch this at create time.)
- `TARGET_LAG` controls freshness; Snowflake schedules the refresh.
- The semantic view and agent read **ordinary columns** — fast and consistent.

## Grain
`SURVEY_BASE` is one row per survey response. Each response references exactly one
game round and one player, so both joins are 1:1 — no fan-out, no inflated counts.
In the real data, if a survey could map to many rounds, you'd pick the triggering
round (or use an `ASOF` relationship) to keep the grain.
