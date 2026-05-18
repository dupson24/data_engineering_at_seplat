# =============================================================================
# Cofense PhishMe — Shared Helper Functions
# Workspace : /PhishMe/helpers/helpers.py
# Usage     : %run ../helpers/helpers  (AFTER %run ../config/config)
# Requires  : config.py already run (TOKEN, BASE_URL, HEADERS, etc. in scope)
# =============================================================================

import requests
import time
import json

# Build auth header from secret — called once per notebook
TOKEN   = dbutils.secrets.get(scope=API_SECRET_SCOPE, key=API_SECRET_KEY)
HEADERS = {"Authorization": f'Token token="{TOKEN}"'}

# ── MOUNT ─────────────────────────────────────────────────────────────────────
def ensure_mount():
    """Mount ADLS Gen2 container if not already mounted."""
    if MOUNT_POINT not in [m.mountPoint for m in dbutils.fs.mounts()]:
        dbutils.fs.mount(
            source=f"wasbs://{CONTAINER}@{STORAGE_ACCOUNT}.blob.core.windows.net",
            mount_point=MOUNT_POINT,
            extra_configs={
                f"fs.azure.account.key.{STORAGE_ACCOUNT}.blob.core.windows.net":
                    dbutils.secrets.get(scope=API_SECRET_SCOPE, key=STORAGE_SECRET)
            }
        )
        print(f"✅ Mounted → {MOUNT_POINT}")
    else:
        print(f"✅ Already mounted → {MOUNT_POINT}")


# ── PATHS ─────────────────────────────────────────────────────────────────────
def raw_path(folder, filename):
    """Build dated path: /mnt/PhishMe/raw/<folder>/YYYY/MM/DD/<file>"""
    return f"{RAW_BASE}/{folder}/{DATE_PATH}/{filename}"


# ── LAND ──────────────────────────────────────────────────────────────────────
def land(content, folder, filename):
    """Write raw string content to ADLS and return the path."""
    path = raw_path(folder, filename)
    dbutils.fs.put(path, content, overwrite=True)
    print(f"  ✅ {path}  ({len(content):,} bytes)")
    return path


# ── API GET ───────────────────────────────────────────────────────────────────
def api_get(endpoint, params=None):
    """
    GET request with auth. Handles:
      401 → raises with clear message
      403 → parses rate-limit wait, sleeps, retries once
      404 → returns None (not an error)
      other errors → raises via raise_for_status
    """
    resp = requests.get(f"{BASE_URL}{endpoint}", headers=HEADERS, params=params)

    if resp.status_code == 401:
        raise Exception(
            f"❌ Invalid token — check '{API_SECRET_KEY}' in scope '{API_SECRET_SCOPE}'"
        )

    if resp.status_code == 403:
        try:
            secs = int(''.join(filter(str.isdigit,
                       resp.text.split("seconds")[0].split(":")[-1].strip())))
        except Exception:
            secs = 60
        wait = secs + RATE_LIMIT_BUFFER
        print(f"  ⏳ Rate limited — sleeping {wait}s...")
        time.sleep(wait)
        return api_get(endpoint, params)   # retry once

    if resp.status_code == 404:
        print(f"  ⚠ 404 Not found: {endpoint}")
        return None

    resp.raise_for_status()
    return resp


# ── API POST ──────────────────────────────────────────────────────────────────
def api_post(endpoint, data=None, params=None):
    """POST request with auth. Send body as form data (data=), not query params."""
    resp = requests.post(
        f"{BASE_URL}{endpoint}",
        headers=HEADERS,
        data=data,
        params=params
    )
    resp.raise_for_status()
    return resp


# ── PAGINATE ──────────────────────────────────────────────────────────────────
def get_all_pages(endpoint, params=None):
    """
    Fetch all pages from a JSON paginated endpoint.
    Returns flat list of all records across pages.
    """
    records, page = [], 1
    params = params or {}
    while True:
        params.update({"page": page, "per_page": 50})
        resp = api_get(endpoint, params=params)
        if not resp:
            break
        data = resp.json()
        if not data:
            break
        records.extend(data)
        print(f"    Page {page}: {len(data)} records")
        if len(data) < 50:
            break
        page += 1
    return records


# ── AUDIT LOG ─────────────────────────────────────────────────────────────────
def log_run(endpoint, status, records, path):
    """Append one JSONL entry to today's audit log."""
    log_path = f"{AUDIT_PATH}/{DATE_PATH}/run_log_{TIMESTAMP}.jsonl"
    entry = json.dumps({
        "timestamp" : TIMESTAMP,
        "endpoint"  : endpoint,
        "status"    : status,
        "records"   : records,
        "path"      : path
    }) + "\n"
    try:
        existing = dbutils.fs.head(log_path, 100000)
        dbutils.fs.put(log_path, existing + entry, overwrite=True)
    except Exception:
        dbutils.fs.put(log_path, entry, overwrite=True)


# ── SAVE / LOAD JOBS ──────────────────────────────────────────────────────────
def save_jobs(jobs, label):
    """Persist a list of export jobs to ADLS for pickup by the next notebook."""
    path = f"{JOBS_PATH}/{label}_{TIMESTAMP}.json"
    dbutils.fs.put(path, json.dumps(jobs, indent=2), overwrite=True)
    print(f"  📋 {len(jobs)} jobs saved → {path}")
    return path


def load_latest_jobs(label):
    """Load the most recent jobs file matching the given label from ADLS."""
    try:
        files   = dbutils.fs.ls(JOBS_PATH)
        matches = sorted([f.path for f in files if label in f.path])
        if not matches:
            print(f"  ⚠ No job files found for label: '{label}'")
            return []
        latest = matches[-1]
        print(f"  📋 Loading from: {latest}")
        return json.loads(dbutils.fs.head(latest, 500000))
    except Exception as e:
        print(f"  ❌ Could not load jobs: {e}")
        return []


# ── DOWNLOAD EXPORT ───────────────────────────────────────────────────────────
def check_and_download_export(export_id, sid):
    """
    Check a scenario export's status.
    Returns (downloaded: bool, path: str or "")
      - True  → export completed and file landed
      - False → still pending or failed
    """
    check = requests.get(
        f"{BASE_URL}/scenario_exports/{export_id}",
        headers=HEADERS
    )
    print(f"    Poll HTTP: {check.status_code}")

    if check.status_code != 200:
        return False, ""

    try:
        result   = check.json()
        status   = result.get("status", "unknown")
        dl_url   = result.get("download_url", "")
        progress = result.get("progress", 0)
        print(f"    Export status: {status} | progress: {progress}%")

        if status == "completed" and dl_url:
            full_url = dl_url if dl_url.startswith("http") \
                               else f"https://login.phishme.co.uk{dl_url}"
            dl   = requests.get(full_url, headers=HEADERS, allow_redirects=True)
            path = land(dl.text, f"scenario_full_csv/{sid}",
                        f"full_csv_{sid}_{TIMESTAMP}.csv")
            return True, path

        return False, ""   # still in_progress / initial

    except Exception:
        # Some exports return raw CSV directly on 200 instead of JSON
        if len(check.text) > 100:
            path = land(check.text, f"scenario_full_csv/{sid}",
                        f"full_csv_{sid}_{TIMESTAMP}.csv")
            return True, path
        return False, ""
