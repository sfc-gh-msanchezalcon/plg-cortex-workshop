# PLG Cortex Workshop — Player-Email Survey Analytics

A self-guided, ~60-minute hands-on lab for the Postcode Lottery Group data team, built on **your own** clarity/tone survey use case.

> **This builds on the prototype André's team already created — it doesn't replace it.** Same use case, same four stages — Foundation → Core AI → Advanced AI → Consumption. The one change is the architecture underneath, and it directly answers the question the team raised: *does natural-language analysis really need this much extra code to run fast and cheap?*

---

## The one idea to take away

**Precompute the *features*, generate the *answers* live.**

Sentiment, topic and embeddings are stable per row → materialise them **once**, incrementally, and reuse everywhere. Summaries and synthesis vary per question → leave those to query time. That is what keeps this both flexible *and* cheap — and it removes the need for the hand-rolled batching, truncation and pre-filter tricks in the current prototype.

You are **not** materialising the answers (which would lock the data down). You are materialising the per-row enrichment. Cortex Analyst still writes its own varying SQL — filtering, grouping, trending — over the enriched columns. You lose no flexibility and drop almost all of the token cost.

---

## How the lab works

- **Self-guided and independent.** Every notebook stands on its own — instructions, expected outputs, self-check cells, troubleshooting, and a fast-path to catch up if you fall behind. No presenter required.
- **Self-paced.** The ~60-minute timing below is a target, not a gate. Work at your own speed.
- **Your own sandbox.** You run `setup/00_setup.ipynb` first; it creates a private schema + warehouse just for you and generates a small synthetic survey dataset. Nobody blocks anybody.
- **Synthetic data.** No real player data is used — the dataset is generated in-account and mirrors the shape of the KTV survey (clarity/tone ratings + Dutch free text + game-round performance).

## Run order (~60 min)

| Step | Notebook | ~min | You will |
|---|---|---|---|
| 0 | `setup/00_setup.ipynb` | 8 | Create your sandbox + generate synthetic survey data |
| 1 | `notebooks/01_foundation_semantic_view.ipynb` | 12 | Build a semantic view and ask it questions in natural language |
| 2 | `notebooks/02_core_ai_precompute.ipynb` | 18 | Enrich free text once (sentiment + topic) and summarise live — the core of the lab |
| 3 | `notebooks/03_advanced_ai_search.ipynb` | 12 | Add a Cortex Search service for "find feedback like this" *(stretch — skip if short on time)* |
| 4 | `notebooks/04_consumption_eval.ipynb` | 8 | Wire a Cortex Agent over it all and score the answers |

## Before you start

See **[SETUP_SNOWFLAKE.md](SETUP_SNOWFLAKE.md)** for the two ways to open this in your account:
1. Connect it as a **git-backed Workspace** (recommended — one-time admin step), or
2. **Import the notebooks** directly (zero setup).

## What's in here

| Path | What it is |
|---|---|
| `SETUP_SNOWFLAKE.md` | How to open this repo in Snowflake (both paths) |
| `AGENDA.md` | The self-paced run-of-show + a pre-flight checklist |
| `PROPOSAL.md` | The workshop format proposal for your team to review |
| `setup/00_setup.ipynb` | Self-serve sandbox + synthetic data generator |
| `notebooks/01–04` | The four hands-on stages |
| `reference/scaffold.sql` | Answer key — every DDL/query in one file |
| `reference/architecture.md` | The four-layer picture + cached-vs-live branches |
| `reference/design-approach.md` | Why we precompute: current design → recommended, side by side |
| `reference/cost_guardrails.md` | Token capping, per-user credit limits, concurrency |

---

*Prepared by Snowflake (Miriam Sánchez Alcón) for Postcode Lottery Group. Questions welcome — this is a draft for your team to shape.*
