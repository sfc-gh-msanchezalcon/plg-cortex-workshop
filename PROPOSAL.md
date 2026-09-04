# Workshop proposal - Cortex analytics on the clarity/tone survey

**For:** André Bloemenkamp and the PLG data team (Anne de Bie, Misael van der Meer, Perry Leijen)
**From:** Miriam Sánchez Alcón, Snowflake
**Status:** draft for your review - feedback welcome before we finalise

---

## This builds on what your team already created

Your team put together an excellent, well-scoped use case: a real problem your
analysts care about - email **clarity** and **tone** survey feedback - with a
working prototype (a semantic view and a Cortex agent). You also raised a fair
question about it: the prototype needed a fair amount of NLP plumbing to stay fast
and cheap, and you asked whether that's the right thing to teach the team.

That question is the reason for this workshop. We keep your use case and your four
stages, and change one thing underneath - which makes most of the token and cost
concerns fall away rather than something you engineer around.

## The one change: precompute the features, generate the answers live

The current prototype calls `SUMMARIZE` / `COMPLETE` each time a question is asked,
which is what drives the batching. Instead, we enrich each row **once, as it lands**
- sentiment (`AI_SENTIMENT`), a topic label (`AI_CLASSIFY`), any structured fields
(`AI_EXTRACT`) - and store them as columns. The semantic view and agent then query
ordinary columns: fast, cheap, and consistent.

The concern about materialising ("won't that lock the data down?") is worth
addressing directly: you'd materialise the **per-row enrichment**, not the
**answers**. Cortex Analyst still writes its own varying SQL over those enriched
columns - no flexibility is lost. And where you want a live free-text summary,
`AI_SUMMARIZE_AGG` / `AI_AGG` handle the map-reduce across many rows for you, with
no context-window limit and no hand-built batching.

## The format we recommend

- **Self-guided, independent, self-paced.** Each person works in their own sandbox
  from a shared repo of notebooks. Everyone builds the whole thing and leaves with
  the full picture; a facilitator monitors and helps if anyone gets stuck.
- **~60 minutes end-to-end.** A small synthetic dataset, scaffolded notebooks (you
  complete a few key blanks and run), and a fast-path in every stage so nobody stalls.
- **Your four stages, kept:** Foundation -> Core AI -> Advanced AI -> Consumption.
  Advanced AI (Cortex Search) is a stretch stage - valuable, but the least central
  to the clarity/tone question, so it's optional if time is short.
- **Synthetic data**, generated in-account - no real player data is used for the lab.

## What each participant walks away with

1. A semantic view over survey + game-round data, queryable in natural language.
2. An incrementally-refreshed enrichment table (sentiment + topic) - the precompute
   pattern, hands-on.
3. A Cortex Search service for theme discovery.
4. A Cortex Agent answering the core business question, with an evaluation score.
5. Direct answers to the questions the team raised (token capping, semantic-view
   review, verified-query matching), embedded in the notebooks.

## The questions the team raised, answered up front

| Question | Short answer (full detail in the notebooks) |
|---|---|
| Is this a good case for Cortex? | Yes - free-text survey feedback at your volume is a strong fit. |
| Can we cap token usage per analyst? | Yes - per-user monthly credit limits via `CORTEX_AI_FUNCTIONS_USAGE_HISTORY` (GA Mar 2026). Timeouts cap *runtime*, not tokens. |
| Is there review functionality for semantic views? | Yes - Cortex Analyst evaluations score SQL correctness against your verified queries. |
| How closely must a question match a verified query? | Semantic similarity, not exact wording. |
| Are we teaching the right thing? | With precompute + aggregate functions, yes - that's the durable pattern. |

---

## What we'd like your input on

1. **Format:** does the self-guided, independent, ~60-minute format work for the
   team (rather than a half-day, group-per-stage session)?
2. **The Stage 2 approach:** are you happy to centre it on **precompute + aggregate
   functions** rather than the batching approach? This is the one substantive change
   and it shapes the notebook content.
3. **Scope:** we scope the lab to **one brand, one email type, clarity + tone** so
   the signal stays clean. Does that work?
4. **Date:** when would you like to run it?

Reply on any of these and we'll finalise. Happy to walk through the repo on a call.
