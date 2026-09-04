# Opening this lab in Snowflake

There are two ways to get these notebooks into your Snowflake account. Pick whichever fits your governance.

- **Option A - Git-backed Workspace** (recommended): one admin runs a ~2-minute setup once, then everyone connects the repo and can pull updates.
- **Option B - Import notebooks** (zero setup): each person imports the `.ipynb` files directly. Nothing to configure.

The repo is **public**, so no personal access token or secret is required either way.

---

## Option A - Git-backed Workspace (recommended)

The repo is `https://github.com/sfc-gh-msanchezalcon/plg-cortex-workshop`. There are two roles below: an **admin does step A1 once
for the whole account**, then **every participant does step A2** to get their own
copy of the lab.

### A1. One-time admin step (once per account)

Snowsight needs an **API integration** before it can reach GitHub. An account
admin (`ACCOUNTADMIN`, or any role with `CREATE INTEGRATION`) runs this once. Open
a **Worksheet** and run:

```sql
USE ROLE ACCOUNTADMIN;

-- Allow Snowsight Workspaces / Git repositories to reach public github.com
CREATE OR REPLACE API INTEGRATION git_api_github
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/')
  ENABLED = TRUE;

-- Let the workshop participants use it. Replace PUBLIC with the role your
-- participants log in as if you want to scope it more tightly.
GRANT USAGE ON INTEGRATION git_api_github TO ROLE PUBLIC;

-- Verify it exists
SHOW API INTEGRATIONS LIKE 'git_api_github';
```

> The repo is **public**, so no token or `git_credentials` secret is needed. (For
> a private repo you'd create a `SECRET` holding a GitHub PAT and add
> `GIT_CREDENTIALS = <secret>` to the integration - not required here.)

Tell participants the integration name (`git_api_github`) and the repo URL.

### A2. Each participant connects the repo (2 minutes)

In Snowsight:

1. Left nav -> **Projects » Workspaces**.
2. Top-left **My Workspace** dropdown -> **＋ (Add / Create)** -> **From Git repository**.
3. Fill the dialog:
   - **Repository URL:** `https://github.com/sfc-gh-msanchezalcon/plg-cortex-workshop.git`
   - **API integration:** `git_api_github`  *(from step A1)*
   - **Personal access token / credentials:** leave **empty** (public repo)
   - **Workspace name:** e.g. `plg-cortex-workshop`
4. Click **Create**. Snowsight clones the repo into your workspace on the `main` branch.
5. In the file tree, open **`setup/00_setup.ipynb`** and run it, then `01` -> `04`
   in `notebooks/`.

**Getting updates later:** if Miriam pushes changes, use the branch/Git control at
the top of the workspace and choose **Pull** (or **Fetch**) to sync.

**Committing your own edits (optional):** your workspace is your own branch/clone -
editing notebooks won't affect anyone else. You don't need to push anything for
the lab.

---

## Option B - Import the notebooks (zero setup)

No integration, no admin. Each participant:

1. Download the five `.ipynb` files from `https://github.com/sfc-gh-msanchezalcon/plg-cortex-workshop` (the `setup/` and `notebooks/` folders).
2. In Snowsight: **Projects » Notebooks » + Notebook » Import .ipynb file**.
3. Import each notebook. Run `00_setup` first, then `01` -> `04` in order.
4. Keep `reference/scaffold.sql` open in a worksheet as your answer key.

Trade-off: no one-click "pull updates" - but nothing to configure and no admin involvement.

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
