# Opening this lab in Snowflake

There are two ways to get these notebooks into your Snowflake account. Pick whichever fits your governance.

- **Option A — Git-backed Workspace** (recommended): one admin runs a ~2-minute setup once, then everyone connects the repo and can pull updates.
- **Option B — Import notebooks** (zero setup): each person imports the `.ipynb` files directly. Nothing to configure.

The repo is **public**, so no personal access token or secret is required either way.

---

## Option A — Git-backed Workspace (recommended)

### A1. One-time admin step (once per account)

An account admin (or a role with `CREATE INTEGRATION`) runs this once so Snowflake can reach GitHub:

```sql
-- One-time: allow Snowsight Workspaces to connect to public github.com repos
CREATE OR REPLACE API INTEGRATION git_api_github
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/')
  ENABLED = TRUE;

-- Let the workshop roles use it (adjust role name as needed)
GRANT USAGE ON INTEGRATION git_api_github TO ROLE PUBLIC;
```

> Because the repo is public, no `git_credentials`/secret is needed. For a private repo you would add a `SECRET` holding a GitHub PAT and reference it in the integration — not required here.

### A2. Each participant connects the repo

In Snowsight:

1. **Projects » Workspaces**
2. **Create » Workspace from Git repository**
3. Repository URL: `<REPO_URL>`  *(paste the link Miriam shared)*
4. API integration: `git_api_github`
5. Public repo → leave credentials empty → **Create**

You now have the full repo as a workspace. Open `setup/00_setup.ipynb` and start. Pull later updates with the workspace's **Fetch/Pull** control.

---

## Option B — Import the notebooks (zero setup)

No integration, no admin. Each participant:

1. Download the five `.ipynb` files from `<REPO_URL>` (the `setup/` and `notebooks/` folders).
2. In Snowsight: **Projects » Notebooks » + Notebook » Import .ipynb file**.
3. Import each notebook. Run `00_setup` first, then `01` → `04` in order.
4. Keep `reference/scaffold.sql` open in a worksheet as your answer key.

Trade-off: no one-click "pull updates" — but nothing to configure and no admin involvement.

---

## What every participant needs

- A role that can `CREATE SCHEMA` and `CREATE WAREHOUSE` (the `00_setup` notebook makes your own private sandbox), **or** an admin pre-creates one sandbox schema/warehouse per person and you skip those cells.
- Cortex functions enabled in the account (`AI_SENTIMENT`, `AI_CLASSIFY`, `AI_FILTER`, `AI_AGG`, `AI_SUMMARIZE_AGG`, Cortex Analyst, Cortex Search, Cortex Agents).
- Region note: Cortex AI functions must be available in your account's region, or `CORTEX_ENABLED_CROSS_REGION` set. `00_setup` includes a check cell.

## Quick troubleshooting

| Symptom | Fix |
|---|---|
| "Workspace from Git" not visible | The API integration (A1) isn't created or your role lacks `USAGE` on it. |
| `CREATE WAREHOUSE` denied in `00_setup` | Ask an admin to pre-create your sandbox warehouse and skip that cell (instructions inline). |
| AI function "not available in region" | Set `ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';` (admin) or run in a supported region. |
| A stage is taking too long | Every stage has a **fast-path** cell that builds its output from `reference/scaffold.sql` so you can keep moving. |
