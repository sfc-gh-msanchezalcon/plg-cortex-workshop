# Proposal — how we'd run the Cortex workshop

**For:** André Bloemenkamp and the PLG data team (Anne de Bie, Misael van der Meer, Perry Leijen)
**From:** Miriam Sánchez Alcón, Snowflake
**Status:** draft for your review — please tell us what to change before we lock it

---

## Start here: this is your idea

Your deck (28-07-2026) is one of the clearest use-case write-ups we've been handed. You picked a real problem your analysts care about — email **clarity** and **tone** survey feedback — built a working demo with a semantic view and a Cortex agent, and were honest about the part that bugged you: you had to write a lot of NLP plumbing (batches of 50, `LEFT()` truncation, eight pre-filter tricks) to keep it fast and cheap, and you asked *"are we teaching our analysts the right thing?"*

That question is exactly right, and it's the reason this proposal exists. We keep your use case and your four stages. We change one thing underneath — and doing so makes most of your token/cost worries disappear rather than something you engineer around.

## The one change: precompute the features, generate the answers live

Today your verified queries call `SUMMARIZE` / `COMPLETE` **every time a question is asked** — hence the batching. Instead, we enrich each row **once, when it lands** — sentiment (`AI_SENTIMENT`), a topic label (`AI_CLASSIFY`), structured fields (`AI_EXTRACT`) — and store them as columns. The semantic view and agent then query ordinary columns: fast, cheap, consistent.

Your reason for *not* materialising was that it would "lock the data down." The thing to untangle: you'd materialise the **per-row enrichment**, not the **answers**. Cortex Analyst still writes its own varying SQL over those enriched columns. You lose no flexibility. And where you *do* want a live free-text summary, `AI_SUMMARIZE_AGG` / `AI_AGG` do the map-reduce over many rows for you — no context-window limit, no hand-rolled batching.

## The format we recommend

- **Self-guided, independent, self-paced.** Each person works in their own sandbox from a shared repo of notebooks. No presenter, no group-per-stage split — everyone builds the whole thing and leaves with the full mental model. Miriam monitors and helps if anyone gets stuck.
- **~60 minutes end-to-end.** Small synthetic dataset, scaffolded notebooks (you fill the key blanks and run), and a fast-path in every stage so nobody stalls.
- **Your four stages, kept:** Foundation → Core AI → Advanced AI → Consumption. Advanced AI (Cortex Search) is a stretch stage — valuable, but the least central to the clarity/tone question, so it's skippable if time is tight.
- **Synthetic data**, generated in-account — no real player data involved for the lab.

## What you'll each walk away with

1. A semantic view over survey + game-round data, queryable in natural language.
2. An incrementally-refreshed enrichment table (sentiment + topic) — the precompute pattern in your hands.
3. A Cortex Search service for theme discovery.
4. A Cortex Agent answering the core business question, with an evaluation score.
5. Direct answers to all nine questions in your deck (token capping, semantic-view review, verified-query matching), embedded in the notebooks.

## Your questions, answered up front

| Your question | Short answer (full detail in the notebooks) |
|---|---|
| Is this a good case for Cortex? | Yes — free-text survey feedback at your volume is a textbook fit. |
| Can we cap token usage per analyst? | Yes — per-user monthly credit limits via `CORTEX_AI_FUNCTIONS_USAGE_HISTORY` (GA Mar 2026). Timeouts cap *runtime*, not tokens. |
| Is there review functionality for semantic views? | Yes — Cortex Analyst evaluations score SQL correctness against your verified queries. |
| How closely must a question match a verified query? | Semantic similarity, not exact wording. |
| Are we teaching the right thing? | With precompute + aggregate functions, yes — that's the durable pattern. |

---

## What we need from you before we lock it

1. **Format:** are you happy with the self-guided, independent, ~60-minute format (instead of the half-day, group-per-stage plan)?
2. **The Stage 2 reframe:** are you happy to teach **precompute + aggregate functions** rather than the batching workaround? This is the one substantive change and it drives the notebook content.
3. **Scope:** we scope the demo to **one brand, one email type, clarity + tone** so the signal stays clean. OK?
4. **Date:** when should we run it after the summer break?

Reply on any of these and we'll finalise. Happy to jump on a call to walk through the repo.
