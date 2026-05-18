# ═════════════════════════════════════════════════════════════════════════════
# 1. USERS
# ═════════════════════════════════════════════════════════════════════════════
print("\n=== 1. USERS ===")
try:
    resp = api_get("/users.csv")
    path = land(resp.text, "users", f"users_{TIMESTAMP}.csv")
    log_run("/users.csv", "success", len(resp.text.strip().split("\n")) - 1, path)
except Exception as e:
    print(f"  ❌ {e}")
    log_run("/users.csv", f"error: {e}", 0, "")

# ═════════════════════════════════════════════════════════════════════════════
# 2. SCENARIOS
# ═════════════════════════════════════════════════════════════════════════════
print("\n=== 2. SCENARIOS ===")
scenario_ids = []
try:
    scenarios = get_all_pages("/scenarios")
    path = land(json.dumps(scenarios, indent=2), "scenarios", f"scenarios_{TIMESTAMP}.json")
    scenario_ids = [s["id"] for s in scenarios]
    log_run("/scenarios", "success", len(scenarios), path)
    print(f"  Total: {len(scenarios)}")
except Exception as e:
    print(f"  ❌ {e}")
    log_run("/scenarios", f"error: {e}", 0, "")

# ═════════════════════════════════════════════════════════════════════════════
# 3. SCENARIO GROUPS
# ═════════════════════════════════════════════════════════════════════════════
print("\n=== 3. SCENARIO GROUPS ===")
scenario_group_ids = []
try:
    groups = get_all_pages("/scenarios/groups")
    path = land(json.dumps(groups, indent=2), "scenario_groups", f"scenario_groups_{TIMESTAMP}.json")
    scenario_group_ids = [g["id"] for g in groups]
    log_run("/scenarios/groups", "success", len(groups), path)
    print(f"  Total: {len(groups)}")
except Exception as e:
    print(f"  ❌ {e}")
    log_run("/scenarios/groups", f"error: {e}", 0, "")

# Group details
for gid in scenario_group_ids:
    try:
        resp = api_get(f"/scenarios/groups/{gid}")
        if resp:
            path = land(resp.text, f"scenario_groups/{gid}", f"group_{gid}_{TIMESTAMP}.json")
            log_run(f"/scenarios/groups/{gid}", "success", 1, path)
    except Exception as e:
        print(f"  ❌ Group {gid}: {e}")

# ═════════════════════════════════════════════════════════════════════════════
# 4. SCENARIO FULL CSVs (background export — avoids rate limit)
# ═════════════════════════════════════════════════════════════════════════════
print("\n=== 4. SCENARIO FULL CSVs ===")
for sid in scenario_ids:
    print(f"\n  Scenario: {sid}")
    try:
        create_resp = api_post("/scenario_exports", params={"id": sid})
        export_data = create_resp.json()
        export_id = export_data[0]["id"] if isinstance(export_data, list) else export_data["id"]
        print(f"    Export created: {export_id}")
        path = poll_for_download(
            export_id,
            f"scenario_full_csv/{sid}",
            f"full_csv_{sid}_{TIMESTAMP}.csv"
        )
        if path:
            log_run(f"/scenario_exports/{sid}", "success", 1, path)
    except Exception as e:
        print(f"    ❌ {e}")
        log_run(f"/scenario_exports/{sid}", f"error: {e}", 0, "")

# ═════════════════════════════════════════════════════════════════════════════
# 5. SCENARIO ACTIVITY TIMELINES
# ═════════════════════════════════════════════════════════════════════════════
print("\n=== 5. ACTIVITY TIMELINES ===")
for sid in scenario_ids:
    try:
        resp = api_get(f"/scenarios/{sid}/activity_timeline")
        if resp:
            path = land(resp.text, f"scenario_activity_timeline/{sid}",
                        f"timeline_{sid}_{TIMESTAMP}.csv")
            log_run(f"/scenarios/{sid}/activity_timeline", "success", 1, path)
    except Exception as e:
        print(f"  ❌ Timeline {sid}: {e}")

# ═════════════════════════════════════════════════════════════════════════════
# 6. ENROLLMENTS
# ═════════════════════════════════════════════════════════════════════════════
print("\n=== 6. ENROLLMENTS ===")
try:
    resp = api_get("/enrollments")
    if resp:
        path = land(resp.text, "enrollments", f"enrollments_{TIMESTAMP}.csv")
        log_run("/enrollments", "success", len(resp.text.strip().split("\n")) - 1, path)
except Exception as e:
    print(f"  ❌ {e}")
    log_run("/enrollments", f"error: {e}", 0, "")

# ═════════════════════════════════════════════════════════════════════════════
# 7. ENGAGEMENT SCORES
# ═════════════════════════════════════════════════════════════════════════════
print("\n=== 7. ENGAGEMENT SCORES ===")
date_params = {"filter[date_filter_start]": "2024-01-01", "filter[date_filter_end]": TODAY}

# 7a — JSON
try:
    scores = get_all_pages("/engagement_scores.json", params=date_params)
    path = land(json.dumps(scores, indent=2), "engagement_scores",
                f"engagement_scores_{TIMESTAMP}.json")
    log_run("/engagement_scores.json", "success", len(scores), path)
except Exception as e:
    print(f"  ❌ JSON: {e}")
    log_run("/engagement_scores.json", f"error: {e}", 0, "")

# 7b — Async CSV
try:
    api_get("/engagement_scores.csv", params=date_params)
    print("  Async CSV triggered, polling...")
    max_wait, waited = 600, 0
    while waited < max_wait:
        notify = api_get("/engagement_export_notifications")
        if notify:
            # API returns a list — check first item
            data = notify.json()
            item = data[0] if isinstance(data, list) else data
            if item.get("expires_at"):
                dl = requests.get(
                    f"https://login.phishme.co.uk{item['download_link']}",
                    headers=HEADERS
                )
                path = land(dl.text, "engagement_scores",
                            f"engagement_scores_{TIMESTAMP}.csv")
                log_run("/engagement_scores.csv", "success", 1, path)
                print("  ✅ Engagement CSV downloaded")
                break
        print(f"  ⏳ Waiting... ({waited}s)")
        time.sleep(20)
        waited += 20
except Exception as e:
    print(f"  ❌ CSV: {e}")
    log_run("/engagement_scores.csv", f"error: {e}", 0, "")

# ═════════════════════════════════════════════════════════════════════════════
# 8. REPEAT CLICKERS
# ═════════════════════════════════════════════════════════════════════════════
print("\n=== 8. REPEAT CLICKERS ===")
try:
    create = api_post("/repeat_clickers_exports",
                      params={"scenario_type": "all",
                              "date_filter_start": "2024-01-01",
                              "date_filter_end": TODAY})
    export_data = create.json()
    rc_id = export_data[0]["id"] if isinstance(export_data, list) else export_data["id"]
    print(f"  Export created: {rc_id}")
    max_wait, waited = 600, 0
    while waited < max_wait:
        check = requests.get(f"{BASE_URL}/repeat_clickers_exports/{rc_id}",
                             headers=HEADERS, allow_redirects=True)
        if check.status_code == 200 and len(check.text) > 100:
            path = land(check.text, "repeat_clickers", f"repeat_clickers_{TIMESTAMP}.csv")
            log_run("/repeat_clickers_exports", "success", 1, path)
            print("  ✅ Downloaded")
            break
        print(f"  ⏳ Waiting... ({waited}s)")
        time.sleep(15)
        waited += 15
except Exception as e:
    print(f"  ❌ {e}")
    log_run("/repeat_clickers_exports", f"error: {e}", 0, "")

# ═════════════════════════════════════════════════════════════════════════════
# 9. ACTIVITY LOGS
# ═════════════════════════════════════════════════════════════════════════════
print("\n=== 9. ACTIVITY LOGS ===")
log_params = {"filter[start_date]": YESTERDAY, "filter[end_date]": TODAY}

try:
    resp = api_get("/activity_logs.csv", params=log_params)
    if resp:
        path = land(resp.text, "activity_logs", f"activity_logs_{TIMESTAMP}.csv")
        log_run("/activity_logs.csv", "success", 1, path)
except Exception as e:
    print(f"  ❌ CSV: {e}")

try:
    logs = get_all_pages("/activity_logs.json", params=log_params)
    path = land(json.dumps(logs, indent=2), "activity_logs", f"activity_logs_{TIMESTAMP}.json")
    log_run("/activity_logs.json", "success", len(logs), path)
except Exception as e:
    print(f"  ❌ JSON: {e}")

# ═════════════════════════════════════════════════════════════════════════════
print(f"\n✅ Pipeline complete: {datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}")
print(f"\nData landed under: {MOUNT}/raw/")