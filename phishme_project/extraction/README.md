# Cofense PhishMe — Databricks Pipeline
**Seplat Energy | IT Security | Data Engineering**

---

## Workspace Structure

Upload the following to Databricks workspace exactly as shown:

```
/PhishMe/
├── config/
│   └── config.py               ← All settings — edit this file only
├── helpers/
│   └── helpers.py              ← Shared functions (api_get, land, log_run, etc.)
├── notebooks/
│   ├── 00_mount_setup.py       ← One-time setup — run manually once
│   ├── 01_extract.py           ← Daily extract (all endpoints except scenario CSVs)
│   ├── 02_trigger_exports.py   ← Trigger scenario CSV background exports
│   └── 03_download_exports.py  ← Download completed exports 30 mins later
└── workflow/
    └── PhishMe_Daily_Pipeline.json  ← Import into Databricks Workflows
```

---

## First-Time Setup

### Step 1 — Upload files to Databricks workspace
In Databricks → Workspace → right-click → Import  
Upload each `.py` file to its matching folder path shown above.

### Step 2 — Verify Azure Key Vault secrets
Two secrets must exist in `SEPdatabrickskv` Key Vault, accessible via scope `CorpAvailScope`:

| Secret Name       | Value                              |
|-------------------|------------------------------------|
| `PhishMe-API-Key` | PhishMe API read token (32 chars)  |
| `CorpAvailkeys`   | ADLS Gen2 storage account key      |

### Step 3 — Run 00_mount_setup.py manually
Open the notebook and run all cells. Confirms:
- Token retrieval works
- Storage key works
- `/mnt/PhishMe` mounts successfully
- All raw folders created
- API returns HTTP 200 on test call

### Step 4 — Import the workflow
Databricks → Workflows → Create Job → Import JSON  
Select `workflow/PhishMe_Daily_Pipeline.json`

### Step 5 — Run once manually to verify
Trigger the workflow manually before enabling the schedule.

---

## Daily Schedule

| Time (UTC) | Task                   | Duration    | Description                          |
|------------|------------------------|-------------|--------------------------------------|
| 01:00      | `01_extract`           | ~15-20 mins | All endpoints except scenario CSVs   |
| ~01:20     | `02_trigger_exports`   | ~1-2 mins   | Fire background export for each scenario |
| ~01:50     | `03_download_exports`  | ~5-10 mins  | Download completed exports           |

The 30-minute gap between task 2 and task 3 is built into the workflow via retry interval — PhishMe needs time to generate the background CSVs server-side.

---

## ADLS Folder Structure

All data lands under `/mnt/PhishMe/raw/YYYY/MM/DD/`:

```
/mnt/PhishMe/raw/
├── users/
├── scenarios/
├── scenario_groups/
│   └── {group_uuid}/
├── scenario_full_csv/
│   └── {scenario_uuid}/
├── scenario_activity_timeline/
│   └── {scenario_uuid}/
├── enrollments/                  ← Requires read-write token
├── engagement_scores/
├── repeat_clickers/
├── activity_logs/
├── _jobs/                        ← Inter-notebook handoff files
└── _audit_log/                   ← Run log per day (JSONL)
```

---

## Config Reference (`config/config.py`)

| Variable          | Value                                  | Change if...               |
|-------------------|----------------------------------------|----------------------------|
| `API_SECRET_KEY`  | `PhishMe-API-Key`                      | Token renamed in AKV       |
| `API_SECRET_SCOPE`| `CorpAvailScope`                       | Scope changes              |
| `BASE_URL`        | `https://login.phishme.co.uk/api/v2`   | API region changes         |
| `MOUNT_POINT`     | `/mnt/PhishMe`                         | Mount path changes         |
| `HISTORY_START`   | `2024-01-01`                           | Pull window changes        |

---

## Enrollments Note

The `/enrollments` endpoint requires a **read-write API token**.  
Current token is read-only — notebook 01 will log `skipped-read-only-token` and continue.  
To enable: request a read-write token from PhishMe admin → update `PhishMe-API-Key` in AKV.

---

## Troubleshooting

| Symptom                          | Fix                                                              |
|----------------------------------|------------------------------------------------------------------|
| `❌ Invalid token`               | Regenerate token in PhishMe → update AKV secret `PhishMe-API-Key` |
| `Mount failed`                   | Check `CorpAvailkeys` in AKV matches current storage account key  |
| `No scenario IDs found` in 02    | 01_extract failed — check audit log                              |
| `No pending exports` in 03       | All exports were immediate (good) or 02 failed                   |
| Exports still pending after 03   | Re-run 03 manually 15-30 mins later                              |
| 404 on export poll               | Export link expired — 03 auto-re-triggers                        |
