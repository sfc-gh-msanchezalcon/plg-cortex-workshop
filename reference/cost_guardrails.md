# Cost guardrails

Direct answers to the deck's cost/token questions, plus the settings to run this
safely in production.

## 1. Cap token usage per analyst (the real answer)

What does **not** cap tokens:
- `STATEMENT_TIMEOUT_IN_SECONDS` and the Analyst query timeout cap **runtime**, not tokens.
- The agent usage cap limits the agent, not the SQL it issues underneath.

What does - as of **March 2026** there's an account-usage view,
`SNOWFLAKE.ACCOUNT_USAGE.CORTEX_AI_FUNCTIONS_USAGE_HISTORY`, tracking credits and
tokens per **user, model, function, and query**. Build guardrails on top:

**Per-user monthly credit limit** - a scheduled task checks month-to-date spend
and revokes a user's access to Cortex when they cross budget (restore next month):

```sql
-- Sketch: month-to-date Cortex credits by user
SELECT user_name,
       SUM(token_credits) AS mtd_credits
FROM SNOWFLAKE.ACCOUNT_USAGE.CORTEX_AI_FUNCTIONS_USAGE_HISTORY
WHERE start_time >= DATE_TRUNC('month', CURRENT_TIMESTAMP())
GROUP BY user_name
ORDER BY mtd_credits DESC;
-- Wrap in a scheduled TASK that, above a threshold, revokes a Cortex role/policy
-- from the user, and re-grants at month start.
```

**Runaway-query auto-cancel** - catch a single expensive query and cancel it
before it runs away (query monitoring / a watchdog task on long-running
Cortex queries).

**Account-level guardrails** - a **Budget** on the workshop database/warehouse and
a **spend alert** for the overall ceiling.

## 2. Warehouse + concurrency for the workshop

- Everyone shares `PLG_WORKSHOP_WH` (MEDIUM, multi-cluster 1-3). With a handful of
  participants running small AI functions this is plenty and avoids per-person
  warehouse sprawl.
- If you scale the dataset up a lot or add many participants, either raise
  `MAX_CLUSTER_COUNT` or give heavy users their own XS/S warehouse. AI functions
  queue politely; they don't fail under contention.
- Keep the dataset small for the live build (~4k rows). The incremental Dynamic
  Table means re-runs only touch new rows anyway.

## 3. Governance for production

- **RBAC:** grant `REFERENCES, SELECT` on the semantic view to the analyst role;
  they don't need SELECT on base tables.
- **Lineage:** native - the enriched Dynamic Table and semantic view show up in
  the catalog/lineage automatically.
- **Freshness:** monitor Dynamic Table refresh history; set `TARGET_LAG` to match
  how fresh the survey answers need to be.
- **Model choice:** `COUNT_TOKENS`/enrichment default to small, cheap models;
  only the live synthesis (`AI_AGG`) needs a stronger model.
