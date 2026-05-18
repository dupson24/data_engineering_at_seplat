# ============================================================
# Cofense PhishMe API V2 — Full Extraction Pipeline
# Runs daily. Lands all data to ADLS under /mnt/seplatedw/cofense/raw/
# ============================================================

import requests
import time
import json
import csv
from datetime import datetime, timezone, timedelta
from io import StringIO

# ── CONFIG ───────────────────────────────────────────────────────────────────
TOKEN       = dbutils.secrets.get(scope="CorpAvailScope", key="PhishMe-API-Key")
BASE_URL    = "https://login.phishme.co.uk/api/v2"
HEADERS     = {"Authorization": f'Token token="{TOKEN}"'}
MOUNT       = "/mnt/seplatedw"

# Today's partition path e.g. cofense/raw/users/2026/03/09/
RUN_DATE    = datetime.now(timezone.utc)
DATE_PATH   = RUN_DATE.strftime("%Y/%m/%d")
TIMESTAMP   = RUN_DATE.strftime("%Y%m%dT%H%M%SZ")

# Date window for filtered endpoints (last 24 hours for daily runs)
YESTERDAY   = (RUN_DATE - timedelta(days=1)).strftime("%Y-%m-%d")
TODAY       = RUN_DATE.strftime("%Y-%m-%d")

print(f"Pipeline started: {TIMESTAMP}")
print(f"Date window: {YESTERDAY} → {TODAY}")


# ── HELPERS ──────────────────────────────────────────────────────────────────

def raw_path(endpoint_name, filename):
    """Build ADLS path: /mnt/seplatedw/cofense/raw/<endpoint>/YYYY/MM/DD/<file>"""
    return f"{MOUNT}/cofense/raw/{endpoint_name}/{DATE_PATH}/{filename}"


def api_get(endpoint, params=None):
    """GET request with auth. Handles 401/403/500."""
    url = f"{BASE_URL}{endpoint}"
    response = requests.get(url, headers=HEADERS, params=params)
    if response.status_code == 401:
        raise Exception("❌ API token invalid or expired. Check AKV secret: PhishMe-API-Key")
    if response.status_code == 403:
        # Rate limit on full_csv — parse wait time and retry
        msg = response.text
        try:
            seconds = int(''.join(filter(str.isdigit,
                          msg.split("seconds")[0].split(":")[-1].strip())))
        except:
            seconds = 60
        print(f"  ⏳ Rate limited. Sleeping {seconds + 5}s...")
        time.sleep(seconds + 5)
        return api_get(endpoint, params)
    if response.status_code == 404:
        print(f"  ⚠ 404 Not Found: {endpoint}")
        return None
    response.raise_for_status()
    return response


def api_post(endpoint, params=None):
    """POST request with auth."""
    url = f"{BASE_URL}{endpoint}"
    response = requests.post(url, headers=HEADERS, params=params)
    response.raise_for_status()
    return response


def land(content, endpoint_name, filename):
    """Write raw content string to ADLS."""
    path = raw_path(endpoint_name, filename)
    dbutils.fs.put(path, content, overwrite=True)
    size = len(content)
    print(f"  ✅ Landed → {path} ({size:,} bytes)")
    return path


def get_all_pages(endpoint, params=None):
    """Paginate through all pages and return combined list."""
    all_records = []
    page = 1
    if params is None:
        params = {}
    while True:
        params["page"] = page
        params["per_page"] = 50
        resp = api_get(endpoint, params=params)
        if resp is None:
            break
        data = resp.json()
        if not data:
            break
        all_records.extend(data)
        print(f"    Page {page}: {len(data)} records")
        if len(data) < 50:
            break
        page += 1
    return all_records


def log_run(endpoint, status, records, path):
    """Append a run log entry."""
    log_path = f"{MOUNT}/cofense/raw/_audit_log/{DATE_PATH}/run_log_{TIMESTAMP}.jsonl"
    entry = json.dumps({
        "run_timestamp": TIMESTAMP,
        "endpoint": endpoint,
        "status": status,
        "records_count": records,
        "output_path": path,
        "run_date": TODAY
    }) + "\n"
    try:
        # Append to existing or create new
        try:
            existing = dbutils.fs.head(log_path, 100000)
            dbutils.fs.put(log_path, existing + entry, overwrite=True)
        except:
            dbutils.fs.put(log_path, entry, overwrite=True)
    except Exception as e:
        print(f"  ⚠ Log write failed: {e}")


# ═════════════════════════════════════════════════════════════════════════════
# SECTION 1 — USERS
# ═════════════════════════════════════════════════════════════════════════════
print("\n" + "="*60)
print("1. USERS")
print("="*60)

try:
    resp = api_get("/users.csv")
    path = land(resp.text, "users", f"users_{TIMESTAMP}.csv")
    lines = resp.text.strip().split("\n")
    log_run("/users.csv", "success", len(lines) - 1, path)
except Exception as e:
    print(f"  ❌ Users failed: {e}")
    log_run("/users.csv", f"error: {e}", 0, "")


# ═════════════════════════════════════════════════════════════════════════════
# SECTION 2 — SCENARIOS (all pages)
# ═════════════════════════════════════════════════════════════════════════════
print("\n" + "="*60)
print("2. SCENARIOS")
print("="*60)

scenario_ids = []
try:
    scenarios = get_all_pages("/scenarios")
    content = json.dumps(scenarios, indent=2)
    path = land(content, "scenarios", f"scenarios_{TIMESTAMP}.json")
    scenario_ids = [s["id"] for s in scenarios]
    log_run("/scenarios", "success", len(scenarios), path)
    print(f"  Total scenarios: {len(scenarios)}")
except Exception as e:
    print(f"  ❌ Scenarios failed: {e}")
    log_run("/scenarios", f"error: {e}", 0, "")


# ═════════════════════════════════════════════════════════════════════════════
# SECTION 3 — SCENARIO GROUPS
# ═════════════════════════════════════════════════════════════════════════════
print("\n" + "="*60)
print("3. SCENARIO GROUPS")
print("="*60)

scenario_group_ids = []
try:
    groups = get_all_pages("/scenarios/groups")
    content = json.dumps(groups, indent=2)
    path = land(content, "scenario_groups", f"scenario_groups_{TIMESTAMP}.json")
    scenario_group_ids = [g["id"] for g in groups]
    log_run("/scenarios/groups", "success", len(groups), path)
    print(f"  Total groups: {len(groups)}")
except Exception as e:
    print(f"  ❌ Scenario groups failed: {e}")
    log_run("/scenarios/groups", f"error: {e}", 0, "")


# SECTION 3b — EACH GROUP DETAIL
print("\n  Fetching individual group details...")
for gid in scenario_group_ids:
    try:
        resp = api_get(f"/scenarios/groups/{gid}")
        if resp:
            path = land(resp.text, f"scenario_groups/{gid}", f"group_{gid}_{TIMESTAMP}.json")
            log_run(f"/scenarios/groups/{gid}", "success", 1, path)
    except Exception as e:
        print(f"  ❌ Group {gid} failed: {e}")


# ═════════════════════════════════════════════════════════════════════════════
# SECTION 4 — SCENARIO FULL CSVs (via background export — avoids rate limit)
# ═════════════════════════════════════════════════════════════════════════════
print("\n" + "="*60)
print("4. SCENARIO FULL CSVs (background export)")
print("="*60)

for sid in scenario_ids:
    print(f"\n  Scenario: {sid}")
    try:
        # Step 1: Create background export
        create_resp = api_post("/scenario_exports", params={"id": sid})
        export_data = create_resp.json()
        # Handle list or dict response
        if isinstance(export_data, list):
            export_id = export_data[0]["id"]
        else:
            export_id = export_data["id"]
        print(f"    Export created: {export_id}")

        # Step 2: Poll until ready (max 10 mins)
        max_wait = 600
        waited = 0
        download_url = None
        while waited < max_wait:
            check = api_get(f"/scenario_exports/{export_id}")
            if check and check.status_code == 200:
                try:
                    result = check.json()
                    if result.get("download_url"):
                        download_url = result["download_url"]
                        break
                except:
                    # If it returned CSV directly
                    path = land(check.text, f"scenario_full_csv/{sid}",
                                f"full_csv_{sid}_{TIMESTAMP}.csv")
                    log_run(f"/scenario_exports/{export_id}", "success", 1, path)
                    break
            print(f"    ⏳ Waiting for export... ({waited}s)")
            time.sleep(15)
            waited += 15

        # Step 3: Download from URL if available
        if download_url:
            dl_resp = requests.get(
                f"https://login.phishme.co.uk{download_url}",
                headers=HEADERS,
                allow_redirects=True
            )
            path = land(dl_resp.text, f"scenario_full_csv/{sid}",
                        f"full_csv_{sid}_{TIMESTAMP}.csv")
            log_run(f"/scenario_exports/{sid}", "success", 1, path)

    except Exception as e:
        print(f"    ❌ Full CSV failed for {sid}: {e}")
        log_run(f"/scenario_exports/{sid}", f"error: {e}", 0, "")


# ═════════════════════════════════════════════════════════════════════════════
# SECTION 5 — SCENARIO ACTIVITY TIMELINES
# ═════════════════════════════════════════════════════════════════════════════
print("\n" + "="*60)
print("5. SCENARIO ACTIVITY TIMELINES")
print("="*60)

for sid in scenario_ids:
    try:
        resp = api_get(f"/scenarios/{sid}/activity_timeline")
        if resp:
            path = land(resp.text, f"scenario_activity_timeline/{sid}",
                        f"timeline_{sid}_{TIMESTAMP}.csv")
            log_run(f"/scenarios/{sid}/activity_timeline", "success", 1, path)
            print(f"  ✅ Timeline: {sid}")
    except Exception as e:
        print(f"  ❌ Timeline {sid} failed: {e}")


# ═════════════════════════════════════════════════════════════════════════════
# SECTION 6 — ENROLLMENTS (Learning Management)
# ═════════════════════════════════════════════════════════════════════════════
print("\n" + "="*60)
print("6. ENROLLMENTS")
print("="*60)

enrollment_ids = []
try:
    resp = api_get("/enrollments")
    if resp:
        path = land(resp.text, "enrollments", f"enrollments_{TIMESTAMP}.csv")
        # Parse enrollment IDs from CSV to fetch learner records
        reader = csv.DictReader(StringIO(resp.text))
        # Enrollments CSV — IDs not directly in this response
        # Store raw for transformation layer to handle
        lines = resp.text.strip().split("\n")
        log_run("/enrollments", "success", len(lines) - 1, path)
        print(f"  Total enrollment rows: {len(lines) - 1}")
except Exception as e:
    print(f"  ❌ Enrollments failed: {e}")
    log_run("/enrollments", f"error: {e}", 0, "")


# ═════════════════════════════════════════════════════════════════════════════
# SECTION 7 — ENGAGEMENT SCORES (async CSV + JSON)
# ═════════════════════════════════════════════════════════════════════════════
print("\n" + "="*60)
print("7. EMPLOYEE ENGAGEMENT SCORES")
print("="*60)

# 7a — JSON (paginated, immediate)
try:
    scores = get_all_pages("/engagement_scores.json",
                           params={"filter[date_filter_start]": "2024-01-01",
                                   "filter[date_filter_end]": TODAY})
    content = json.dumps(scores, indent=2)
    path = land(content, "engagement_scores", f"engagement_scores_{TIMESTAMP}.json")
    log_run("/engagement_scores.json", "success", len(scores), path)
except Exception as e:
    print(f"  ❌ Engagement scores JSON failed: {e}")
    log_run("/engagement_scores.json", f"error: {e}", 0, "")

# 7b — Trigger async CSV generation
try:
    trigger = api_get("/engagement_scores.csv",
                      params={"filter[date_filter_start]": "2024-01-01",
                              "filter[date_filter_end]": TODAY})
    print(f"  Async CSV triggered: {trigger.json()}")

    # Poll for completion (max 10 min)
    max_wait = 600
    waited = 0
    while waited < max_wait:
        notify = api_get("/engagement_export_notifications")
        if notify:
            data = notify.json()
            download_link = data.get("download_link", "")
            if data.get("expires_at"):  # completed
                dl = requests.get(
                    f"https://login.phishme.co.uk{download_link}",
                    headers=HEADERS
                )
                path = land(dl.text, "engagement_scores",
                            f"engagement_scores_{TIMESTAMP}.csv")
                log_run("/engagement_scores.csv", "success", 1, path)
                print("  ✅ Engagement CSV downloaded")
                break
        print(f"  ⏳ Waiting for engagement CSV... ({waited}s)")
        time.sleep(20)
        waited += 20
except Exception as e:
    print(f"  ❌ Engagement scores CSV failed: {e}")
    log_run("/engagement_scores.csv", f"error: {e}", 0, "")


# ═════════════════════════════════════════════════════════════════════════════
# SECTION 8 — REPEAT CLICKERS EXPORT
# ═════════════════════════════════════════════════════════════════════════════
print("\n" + "="*60)
print("8. REPEAT CLICKERS")
print("="*60)

try:
    # Create export
    create = api_post("/repeat_clickers_exports",
                      params={"scenario_type": "all",
                              "date_filter_start": "2024-01-01",
                              "date_filter_end": TODAY})
    export_data = create.json()
    if isinstance(export_data, list):
        rc_id = export_data[0]["id"]
    else:
        rc_id = export_data["id"]
    print(f"  Export created: {rc_id}")

    # Poll until ready
    max_wait = 600
    waited = 0
    while waited < max_wait:
        check = requests.get(
            f"{BASE_URL}/repeat_clickers_exports/{rc_id}",
            headers=HEADERS,
            allow_redirects=True
        )
        if check.status_code == 200 and len(check.text) > 100:
            path = land(check.text, "repeat_clickers",
                        f"repeat_clickers_{TIMESTAMP}.csv")
            log_run("/repeat_clickers_exports", "success", 1, path)
            print("  ✅ Repeat clickers downloaded")
            break
        print(f"  ⏳ Waiting for repeat clickers export... ({waited}s)")
        time.sleep(15)
        waited += 15

except Exception as e:
    print(f"  ❌ Repeat clickers failed: {e}")
    log_run("/repeat_clickers_exports", f"error: {e}", 0, "")


# ═════════════════════════════════════════════════════════════════════════════
# SECTION 9 — ACTIVITY LOGS
# ═════════════════════════════════════════════════════════════════════════════
print("\n" + "="*60)
print("9. ACTIVITY LOGS")
print("="*60)

# 9a — CSV
try:
    resp = api_get("/activity_logs.csv",
                   params={"filter[start_date]": YESTERDAY,
                           "filter[end_date]": TODAY})
    if resp:
        path = land(resp.text, "activity_logs",
                    f"activity_logs_{TIMESTAMP}.csv")
        log_run("/activity_logs.csv", "success", 1, path)
except Exception as e:
    print(f"  ❌ Activity logs CSV failed: {e}")

# 9b — JSON (paginated)
try:
    logs = get_all_pages("/activity_logs.json",
                         params={"filter[start_date]": YESTERDAY,
                                 "filter[end_date]": TODAY})
    content = json.dumps(logs, indent=2)
    path = land(content, "activity_logs",
                f"activity_logs_{TIMESTAMP}.json")
    log_run("/activity_logs.json", "success", len(logs), path)
except Exception as e:
    print(f"  ❌ Activity logs JSON failed: {e}")


# ═════════════════════════════════════════════════════════════════════════════
# DONE
# ═════════════════════════════════════════════════════════════════════════════
print("\n" + "="*60)
print(f"✅ Pipeline complete: {datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}")
print("="*60)
print("\nData landed under:")
print(f"  {MOUNT}/cofense/raw/")
print("\nFolders created:")
folders = [
    "users/",
    "scenarios/",
    "scenario_groups/",
    "scenario_full_csv/",
    "scenario_activity_timeline/",
    "enrollments/",
    "engagement_scores/",
    "repeat_clickers/",
    "activity_logs/",
    "_audit_log/"
]
for f in folders:
    print(f"  ├── {f}")
```

---

## What this does

**ADLS folder structure created per run:**
```
/mnt/seplatedw/cofense/raw/
├── users/2026/03/09/users_20260309T120000Z.csv
├── scenarios/2026/03/09/scenarios_20260309T120000Z.json
├── scenario_groups/2026/03/09/scenario_groups_20260309T120000Z.json
├── scenario_full_csv/{uuid}/full_csv_{uuid}_20260309T120000Z.csv
├── scenario_activity_timeline/{uuid}/timeline_{uuid}_20260309T120000Z.csv
├── enrollments/2026/03/09/enrollments_20260309T120000Z.csv
├── engagement_scores/2026/03/09/engagement_scores_20260309T120000Z.json
├── engagement_scores/2026/03/09/engagement_scores_20260309T120000Z.csv
├── repeat_clickers/2026/03/09/repeat_clickers_20260309T120000Z.csv
├── activity_logs/2026/03/09/activity_logs_20260309T120000Z.csv
└── _audit_log/2026/03/09/run_log_20260309T120000Z.jsonl