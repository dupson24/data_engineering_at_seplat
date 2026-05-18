# =============================================================================
# Cofense PhishMe — 01_extract.py
# Workspace : /PhishMe/notebooks/01_extract.py
# Purpose   : Extract all endpoints EXCEPT scenario full CSVs
#             (those are handled by 02_trigger_exports + 03_download_exports)
# Schedule  : Daily 01:00 UTC via Databricks Workflow task "01_extract"
# Runtime   : ~10-20 mins depending on data volume
# =============================================================================

# ── LOAD CONFIG & HELPERS ─────────────────────────────────────────────────────
%run ../config/config
%run ../helpers/helpers

# ── INIT ──────────────────────────────────────────────────────────────────────
ensure_mount()
print(f"\nPipeline : 01_extract")
print(f"Run      : {TIMESTAMP}")
print(f"Window   : {YESTERDAY} → {TODAY}")
print(f"Mount    : {MOUNT_POINT}")
print("=" * 60)

# =============================================================================
# 1. USERS
# =============================================================================
print("\n=== 1. USERS ===")
try:
    resp = api_get("/users.csv")
    path = land(resp.text, "users", f"users_{TIMESTAMP}.csv")
    rows = max(0, len(resp.text.strip().split("\n")) - 1)
    log_run("/users.csv", "success", rows, path)
    print(f"  Rows: {rows}")
except Exception as e:
    print(f"  ❌ {e}")
    log_run("/users.csv", f"error: {e}", 0, "")

# =============================================================================
# 2. SCENARIOS  — also collects IDs for notebooks 02 + 03
# =============================================================================
print("\n=== 2. SCENARIOS ===")
scenario_ids = []
try:
    scenarios    = get_all_pages("/scenarios")
    path         = land(json.dumps(scenarios, indent=2), "scenarios",
                        f"scenarios_{TIMESTAMP}.json")
    scenario_ids = [s["id"] for s in scenarios]
    log_run("/scenarios", "success", len(scenarios), path)
    print(f"  Total: {len(scenarios)}")
except Exception as e:
    print(f"  ❌ {e}")
    log_run("/scenarios", f"error: {e}", 0, "")

# =============================================================================
# 3. SCENARIO GROUPS
# =============================================================================
print("\n=== 3. SCENARIO GROUPS ===")
try:
    groups = get_all_pages("/scenarios/groups")
    path   = land(json.dumps(groups, indent=2), "scenario_groups",
                  f"scenario_groups_{TIMESTAMP}.json")
    log_run("/scenarios/groups", "success", len(groups), path)
    print(f"  Total: {len(groups)}")

    # individual group detail
    for g in groups:
        gid = g["id"]
        try:
            resp = api_get(f"/scenarios/groups/{gid}")
            if resp:
                land(resp.text, f"scenario_groups/{gid}",
                     f"group_{gid}_{TIMESTAMP}.json")
                log_run(f"/scenarios/groups/{gid}", "success", 1, "")
        except Exception as eg:
            print(f"  ⚠ Group {gid}: {eg}")
except Exception as e:
    print(f"  ❌ {e}")
    log_run("/scenarios/groups", f"error: {e}", 0, "")

# =============================================================================
# 4. ACTIVITY TIMELINES  (one per scenario)
# =============================================================================
print("\n=== 4. ACTIVITY TIMELINES ===")
tl_ok, tl_fail = 0, 0
for sid in scenario_ids:
    try:
        resp = api_get(f"/scenarios/{sid}/activity_timeline")
        if resp:
            land(resp.text, f"scenario_activity_timeline/{sid}",
                 f"timeline_{sid}_{TIMESTAMP}.csv")
            log_run(f"/scenarios/{sid}/activity_timeline", "success", 1, "")
            tl_ok += 1
    except Exception as e:
        print(f"  ❌ {sid}: {e}")
        tl_fail += 1
print(f"  ✅ {tl_ok} downloaded | ❌ {tl_fail} failed")

# =============================================================================
# 5. ENROLLMENTS  (read-write token required — graceful skip on 401)
# =============================================================================
print("\n=== 5. ENROLLMENTS ===")
try:
    resp = requests.get(f"{BASE_URL}/enrollments", headers=HEADERS)
    print(f"  HTTP: {resp.status_code}")
    if resp.status_code == 401:
        print("  ⚠ Skipped — /enrollments requires read-write token")
        print("  ℹ Request a read-write token from PhishMe admin if needed")
        log_run("/enrollments", "skipped-read-only-token", 0, "")
    elif resp.status_code == 200:
        path = land(resp.text, "enrollments", f"enrollments_{TIMESTAMP}.csv")
        rows = max(0, len(resp.text.strip().split("\n")) - 1)
        log_run("/enrollments", "success", rows, path)
        print(f"  Rows: {rows}")
    else:
        print(f"  ❌ {resp.status_code}: {resp.text[:200]}")
        log_run("/enrollments", f"error: {resp.status_code}", 0, "")
except Exception as e:
    print(f"  ❌ {e}")
    log_run("/enrollments", f"error: {e}", 0, "")

# =============================================================================
# 6. ENGAGEMENT SCORES
# =============================================================================
print("\n=== 6. ENGAGEMENT SCORES ===")
date_params = {
    "filter[date_filter_start]": HISTORY_START,
    "filter[date_filter_end]"  : TODAY
}

# 6a — JSON (paginated, immediate)
try:
    scores = get_all_pages("/engagement_scores.json", params=date_params.copy())
    path   = land(json.dumps(scores, indent=2), "engagement_scores",
                  f"engagement_scores_{TIMESTAMP}.json")
    log_run("/engagement_scores.json", "success", len(scores), path)
    print(f"  JSON records: {len(scores)}")
except Exception as e:
    print(f"  ❌ JSON: {e}")
    log_run("/engagement_scores.json", f"error: {e}", 0, "")

# 6b — Async CSV export
try:
    api_get("/engagement_scores.csv", params=date_params.copy())
    print("  CSV export triggered, polling...")
    max_wait, waited = 600, 0
    downloaded = False
    while waited < max_wait:
        notify = api_get("/engagement_export_notifications")
        if notify:
            data = notify.json()
            item = data[0] if isinstance(data, list) else data
            if item.get("expires_at"):
                dl_url   = item["download_link"]
                full_url = dl_url if dl_url.startswith("http") \
                                  else f"https://login.phishme.co.uk{dl_url}"
                dl   = requests.get(full_url, headers=HEADERS)
                path = land(dl.text, "engagement_scores",
                            f"engagement_scores_{TIMESTAMP}.csv")
                log_run("/engagement_scores.csv", "success", 1, path)
                print("  ✅ CSV downloaded")
                downloaded = True
                break
        print(f"  ⏳ Waiting... ({waited}s)")
        time.sleep(20)
        waited += 20
    if not downloaded:
        print("  ⚠ Engagement CSV timed out")
        log_run("/engagement_scores.csv", "timeout", 0, "")
except Exception as e:
    print(f"  ❌ CSV: {e}")
    log_run("/engagement_scores.csv", f"error: {e}", 0, "")

# =============================================================================
# 7. REPEAT CLICKERS
# =============================================================================
print("\n=== 7. REPEAT CLICKERS ===")
try:
    create = requests.post(
        f"{BASE_URL}/repeat_clickers_exports",
        headers=HEADERS,
        params={
            "scenario_type"    : "all",
            "date_filter_start": HISTORY_START,
            "date_filter_end"  : TODAY
        }
    )
    export_data = create.json()
    rc_id = export_data[0]["id"] if isinstance(export_data, list) else export_data["id"]
    print(f"  Export triggered: {rc_id}")

    max_wait, waited = 600, 0
    downloaded = False
    while waited < max_wait:
        check = requests.get(
            f"{BASE_URL}/repeat_clickers_exports/{rc_id}",
            headers=HEADERS, allow_redirects=True
        )
        if check.status_code == 200 and len(check.text) > 100:
            path = land(check.text, "repeat_clickers",
                        f"repeat_clickers_{TIMESTAMP}.csv")
            log_run("/repeat_clickers_exports", "success", 1, path)
            print("  ✅ Downloaded")
            downloaded = True
            break
        print(f"  ⏳ Waiting... ({waited}s)")
        time.sleep(15)
        waited += 15
    if not downloaded:
        print("  ⚠ Repeat clickers timed out")
        log_run("/repeat_clickers_exports", "timeout", 0, "")
except Exception as e:
    print(f"  ❌ {e}")
    log_run("/repeat_clickers_exports", f"error: {e}", 0, "")

# =============================================================================
# 8. ACTIVITY LOGS
# =============================================================================
print("\n=== 8. ACTIVITY LOGS ===")
log_params = {"filter[start_date]": YESTERDAY, "filter[end_date]": TODAY}

try:
    resp = api_get("/activity_logs.csv", params=log_params)
    if resp:
        path = land(resp.text, "activity_logs", f"activity_logs_{TIMESTAMP}.csv")
        log_run("/activity_logs.csv", "success", 1, path)
except Exception as e:
    print(f"  ❌ CSV: {e}")
    log_run("/activity_logs.csv", f"error: {e}", 0, "")

try:
    logs = get_all_pages("/activity_logs.json", params=log_params.copy())
    path = land(json.dumps(logs, indent=2), "activity_logs",
                f"activity_logs_{TIMESTAMP}.json")
    log_run("/activity_logs.json", "success", len(logs), path)
    print(f"  JSON records: {len(logs)}")
except Exception as e:
    print(f"  ❌ JSON: {e}")
    log_run("/activity_logs.json", f"error: {e}", 0, "")

# =============================================================================
# HANDOFF — save scenario IDs for notebooks 02 + 03
# =============================================================================
handoff = {
    "scenario_ids": scenario_ids,
    "timestamp"   : TIMESTAMP,
    "run_date"    : TODAY,
    "total"       : len(scenario_ids)
}
save_jobs(handoff, label="scenario_ids")

print(f"\n{'=' * 60}")
print(f"✅ 01_extract complete  |  {TIMESTAMP}")
print(f"   Scenarios identified : {len(scenario_ids)}")
print(f"   Data root            : {RAW_BASE}")
print(f"   Next                 : 02_trigger_exports runs automatically in 5 mins")
print(f"{'=' * 60}")
