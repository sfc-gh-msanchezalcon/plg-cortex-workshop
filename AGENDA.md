# Agenda — self-paced, ~60 minutes

This is a **self-guided** lab. The times are a target so you can gauge your pace; work independently and take the time you need. Miriam is monitoring and available if you get stuck, but nothing here needs a presenter.

## Pre-flight checklist (2 min, before the clock)

- [ ] You can open the repo in Snowflake (see [SETUP_SNOWFLAKE.md](SETUP_SNOWFLAKE.md)).
- [ ] Your role can `CREATE SCHEMA` + `CREATE WAREHOUSE` (or you have a sandbox pre-made).
- [ ] You have run **nothing** yet — start at `00_setup`.

## Run-of-show

| When | Notebook | Goal | Checkpoint (verify yourself) |
|---|---|---|---|
| 0:00–0:08 | `setup/00_setup.ipynb` | Your own sandbox + synthetic survey data | Row counts match the expected numbers shown in the notebook |
| 0:08–0:20 | `01_foundation_semantic_view.ipynb` | A semantic view you can query in natural language | 2 NL questions return correct numbers |
| 0:20–0:38 | `02_core_ai_precompute.ipynb` | Enrich free text **once** (sentiment + topic); summarise live | You can state why sentiment/topic are precomputed but the summary is not |
| 0:38–0:50 | `03_advanced_ai_search.ipynb` *(stretch)* | "Find feedback like this" with Cortex Search | A similarity search returns relevant comments, filtered by game-round performance |
| 0:50–0:58 | `04_consumption_eval.ipynb` | One agent over everything + an evaluation score | Agent answers the core question and you see an eval score |
| 0:58–1:00 | (in `04`) wrap | Your go/no-go read | You've answered the 5 go/no-go questions for yourselves |

## If you fall behind

Every stage notebook has a clearly-marked **FAST-PATH** cell near the top. Running it builds that stage's output straight from `reference/scaffold.sql`, so you can jump forward and keep learning the next stage instead of getting stuck.

## The core question the whole lab builds toward

> *"Compare clarity feedback across good / normal / poor game rounds and explain the main driver of negative sentiment."*

By the end, your Cortex Agent answers this in natural language — routing structured parts to Analyst and the "why" to a live summary — with an evaluation score attached.

## Stretch goals (if you finish early)

- Scale `ROW_COUNT` up in `00_setup` and re-run enrichment — watch the incremental Dynamic Table only process new rows.
- Add a second topic taxonomy value and re-classify.
- Add a verified query for a question your team actually asks, and re-run the evaluation.
