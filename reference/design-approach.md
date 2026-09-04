# Design approach - why we precompute

This lab teaches one architectural idea, and it's worth understanding *why* before
you build it. The Postcode Lottery Group team's existing prototype is solid
engineering - the goal here isn't to replace it, it's to show an approach that
removes most of the moving parts while keeping every capability.

**The principle:** *precompute the features, generate the answers live.*

## Current approach vs the approach this lab teaches

| Concern | Current prototype | Approach in this lab | Why it helps |
|---|---|---|---|
| Sentiment / topic on free text | Computed inside verified queries, every time a question is asked | `AI_SENTIMENT` / `AI_CLASSIFY` **once** in a Dynamic Table (`SURVEY_ENRICHED`) | Stable per row: compute once, reuse in every query |
| Long-text summaries | Hand-built map-reduce: batch, summarise, re-summarise | `AI_AGG` / `AI_SUMMARIZE_AGG` | Built-in map-reduce, **not** context-window bound - no batching code to maintain |
| Oversized inputs | `LEFT()` truncation to fit the context window | Not needed - the aggregate functions handle scale | No silent data loss from truncation |
| Empty / throwaway answers ("nee", "nvt") | Several hand-written filter rules | `AI_FILTER` with one plain-language condition | One rule, easy to read and change |
| Capping token spend | Timeouts + agent usage cap (these limit runtime, not tokens) | Per-user monthly credit limits via `CORTEX_AI_FUNCTIONS_USAGE_HISTORY` | Caps tokens/credits directly - see `cost_guardrails.md` |
| Keeping queries flexible | Enrichment left un-materialised so Cortex can vary its SQL | Materialise the **enrichment**, not the **answers** | Analyst still writes varying SQL over the enriched columns - flexibility is fully preserved |
| Reviewing model quality | (an open question) | Cortex Analyst evaluations (`sql_correctness`) | Scores generated SQL against verified queries and tracks regressions |

## A common concern, addressed

> "If we materialise the data, doesn't that lock it down and stop Cortex from
> varying its own queries?"

No - because you materialise the **per-row enrichment** (sentiment, topic), not the
**answers**. Cortex Analyst still generates its own SQL - filtering, grouping,
trending - over those enriched columns. Nothing is locked. You simply stop
re-invoking the model for the parts of the work that don't change from one
question to the next.

## What stays the same

- The use case: the email **clarity + tone** survey.
- The four stages: Foundation -> Core AI -> Advanced AI -> Consumption.
- The semantic view + Cortex Agent as the surface analysts consume.
- Using a real, familiar dataset to make the learning stick.

The only change is the layer underneath - and that change is what makes the token
and maintenance cost drop.
