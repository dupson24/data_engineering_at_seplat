# =============================================================================
# Cofense PhishMe — 02_trigger_exports.py
# Workspace : /PhishMe/notebooks/02_trigger_exports.py
# Purpose   : Trigger background CSV exports for all scenarios.
#             Runs in seconds — no waiting. Saves job list for notebook 03.
# Schedule  : Daily 01:05 UTC (5 mins after 01_extract finishes)
#             Workflow dependency: depends_on 01_extract
# =============================================================================

%run ../config/config
%run ../helpers/helpers

ensure_mount()
print(f"\nPipeline : 02_trigger_exports")
print(f"Run      : {TIMESTAMP}")
print("=" * 60)

# ── LOAD SCENARIO IDs FROM 01_extract ────────────────────────────────────────
handoff      = load_latest_jobs(label="scenario_ids")
scenario_ids = handoff.get("scenario_ids", []) if isinstance(handoff, dict) else []

if not scenario_ids:
    print("❌ No scenario IDs found. Ensure 01_extract ran successfully.")
    dbutils.notebook.exit("No scenario IDs")

print(f"\nScenarios to process: {len(scenario_ids)}")

# ── TRIGGER EXPORTS ───────────────────────────────────────────────────────────
print("\n=== TRIGGERING BACKGROUND EXPORTS ===")

immediate    = []   # returned CSV directly (200)
pending_jobs = []   # background export queued (202)
failed       = []   # errored

for sid in scenario_ids:
    try:
        resp = requests.get(
            f"{BASE_URL}/scenarios/{sid}/full_csv",
            headers=HEADERS
        )

        if resp.status_code == 200:
            # CSV returned immediately — land it now, no need to queue
            path = land(resp.text, f"scenario_full_csv/{sid}",
                        f"full_csv_{sid}_{TIMESTAMP}.csv")
            log_run(f"/scenarios/{sid}/full_csv", "success-immediate", 1, path)
            immediate.append(sid)
            print(f"  ✅ Immediate: {sid}")

        elif resp.status_code == 202:
            export_id = resp.json().get("background_csv_export")
            pending_jobs.append({"scenario_id": sid, "export_id": export_id})
            print(f"  ⏳ Queued  : {sid} → export {export_id}")

        elif resp.status_code == 403:
            # Rate limited — wait and retry once
            try:
                secs = int(''.join(filter(str.isdigit,
                           resp.text.split("seconds")[0].split(":")[-1].strip())))
            except Exception:
                secs = 120
            print(f"  ⏳ Rate limited {secs}s for {sid} — waiting...")
            time.sleep(secs + RATE_LIMIT_BUFFER)
            retry = requests.get(
                f"{BASE_URL}/scenarios/{sid}/full_csv", headers=HEADERS
            )
            if retry.status_code == 200:
                path = land(retry.text, f"scenario_full_csv/{sid}",
                            f"full_csv_{sid}_{TIMESTAMP}.csv")
                log_run(f"/scenarios/{sid}/full_csv", "success-retry", 1, path)
                immediate.append(sid)
            elif retry.status_code == 202:
                export_id = retry.json().get("background_csv_export")
                pending_jobs.append({"scenario_id": sid, "export_id": export_id})
            else:
                failed.append({"scenario_id": sid, "error": retry.status_code})
                log_run(f"/scenarios/{sid}/full_csv",
                        f"error-{retry.status_code}", 0, "")
        else:
            print(f"  ❌ {sid}: HTTP {resp.status_code}")
            failed.append({"scenario_id": sid, "error": resp.status_code})
            log_run(f"/scenarios/{sid}/full_csv",
                    f"error-{resp.status_code}", 0, "")

    except Exception as e:
        print(f"  ❌ {sid}: {e}")
        failed.append({"scenario_id": sid, "error": str(e)})
        log_run(f"/scenarios/{sid}/full_csv", f"error: {e}", 0, "")

# ── PERSIST PENDING JOBS FOR NOTEBOOK 03 ─────────────────────────────────────
if pending_jobs:
    save_jobs(pending_jobs, label="pending_exports")

if failed:
    save_jobs(failed, label="failed_trigger")

# ── SUMMARY ───────────────────────────────────────────────────────────────────
print(f"\n{'=' * 60}")
print(f"✅ 02_trigger_exports complete  |  {TIMESTAMP}")
print(f"   Immediate downloads  : {len(immediate)}")
print(f"   Pending (background) : {len(pending_jobs)}")
print(f"   Failed               : {len(failed)}")
if pending_jobs:
    print(f"\n   ⏰ 03_download_exports will run in ~30 mins to collect pending exports")
print(f"{'=' * 60}")
