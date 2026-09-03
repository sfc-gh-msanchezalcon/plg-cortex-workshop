# Your approach vs the workshop approach

Your prototype is good engineering. The point of this table is not that it's
wrong — it's that a different architecture makes most of the hard parts
unnecessary. Same use case, same four stages, less code to maintain.

## Side by side

| Concern | Your prototype (deck, 28-07-2026) | Workshop pattern | Why it's better |
|---|---|---|---|
| Free-text sentiment/topic | Computed inside verified queries at question time | `AI_SENTIMENT` / `AI_CLASSIFY` **once** in a Dynamic Table (`SURVEY_ENRICHED`) | Stable per row; compute once, reuse in every query |
| Long-text summaries | Hand-rolled map-reduce: batches of 50 → summarise → re-summarise | `AI_AGG` / `AI_SUMMARIZE_AGG` | Built-in map-reduce, **not** context-window bound; no batching code |
| Oversized inputs | `LEFT()` truncation to fit context window | Not needed — aggregate functions handle scale | No silent data loss from truncation |
| Junk answers ("nee", "nvt", emoji) | 8 hand-written pre-filter rules | `AI_FILTER('is this a substantive comment: ' \|\| text)` | One plain-language rule, easy to change |
| Cost control | Timeouts + agent usage cap (don't actually cap tokens) | Per-user monthly credit limits via `CORTEX_AI_FUNCTIONS_USAGE_HISTORY` | Caps *tokens/credits*, which is what you asked for |
| Flexibility worry | Avoided materialising so Cortex could vary its SQL | Materialise the **enrichment**, not the **answers** | Analyst still writes varying SQL over enriched columns — full flexibility kept |
| "Review" for the model | (open question in deck) | Cortex Analyst evaluations (`sql_correctness`) | Scores SQL vs verified queries; tracks regressions |

## The one misconception worth naming

> "If we materialise, we lock the data down and Cortex can't vary its queries."

You'd be materialising the **per-row enrichment** (sentiment, topic) — not the
**answers**. Cortex Analyst still generates its own SQL — filtering, grouping,
trending — over those enriched columns. Nothing is locked. You simply stop
re-invoking the LLM for the parts of the work that never change per question.

## What stays exactly as you had it
- The use case (email clarity + tone survey).
- The four stages (Foundation → Core AI → Advanced AI → Consumption).
- The semantic view + Cortex Agent as the consumption surface.
- Your instinct that a real dataset your analysts care about is the right way to
  teach this.
