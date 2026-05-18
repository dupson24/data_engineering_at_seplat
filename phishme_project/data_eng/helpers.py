# ── HELPERS ──────────────────────────────────────────────────────────────────
def raw_path(folder, filename):
    return f"{MOUNT}/raw/{folder}/{DATE_PATH}/{filename}"

def land(content, folder, filename):
    path = raw_path(folder, filename)
    dbutils.fs.put(path, content, overwrite=True)
    print(f"  ✅ {path} ({len(content):,} bytes)")
    return path

def api_get(endpoint, params=None):
    url = f"{BASE_URL}{endpoint}"
    resp = requests.get(url, headers=HEADERS, params=params)
    if resp.status_code == 401:
        raise Exception("❌ Invalid token — check PhisMe-API-Key in CorpAvailScope")
    if resp.status_code == 403:
        # Rate limited — parse seconds and retry
        try:
            secs = int(''.join(filter(str.isdigit,
                       resp.text.split("seconds")[0].split(":")[-1].strip())))
        except:
            secs = 60
        print(f"  ⏳ Rate limited, sleeping {secs}s...")
        time.sleep(secs + 5)
        return api_get(endpoint, params)
    if resp.status_code == 404:
        print(f"  ⚠ Not found: {endpoint}")
        return None
    resp.raise_for_status()
    return resp

def api_post(endpoint, params=None):
    resp = requests.post(f"{BASE_URL}{endpoint}", headers=HEADERS, params=params)
    resp.raise_for_status()
    return resp

def get_all_pages(endpoint, params=None):
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

def log_run(endpoint, status, records, path):
    log_path = f"{MOUNT}/raw/_audit_log/{DATE_PATH}/run_log_{TIMESTAMP}.jsonl"
    entry = json.dumps({
        "timestamp": TIMESTAMP,
        "endpoint":  endpoint,
        "status":    status,
        "records":   records,
        "path":      path
    }) + "\n"
    try:
        existing = dbutils.fs.head(log_path, 100000)
        dbutils.fs.put(log_path, existing + entry, overwrite=True)
    except:
        dbutils.fs.put(log_path, entry, overwrite=True)