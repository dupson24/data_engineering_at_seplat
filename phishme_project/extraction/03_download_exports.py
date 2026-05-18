# =============================================================================
# Cofense PhishMe — 03_download_exports.py
# Workspace : /PhishMe/notebooks/03_download_exports.py
# Purpose   : Download completed background CSV exports from notebook 02.
#             Handles expired exports by re-triggering them.
#             Any still-pending after this run are saved for manual retry.
# Schedule  : Daily 01:35 UTC (30 mins after 02_trigger_exports)
#             Workflow dependency: depends_on 02_trigger_exports
# =============================================================================

%run ../config/config
%run ../helpers/helpers

ensure_mount()
print(f"\nPipeline : 03_download_exports")
print(f"Run      : {TIMESTAMP}")
print("=" * 60)

# ── LOAD PENDING JOBS FROM 02_trigger_exports ─────────────────────────────────
pending_jobs = load_latest_jobs(label="pending_exports")

if not pending_jobs:
    print("\n✅ No pending exports found — all scenarios were downloaded immediately in 02.")
    dbutils.notebook.exit("No pending jobs")

print(f"\nPending exports to download: {len(pending_jobs)}")

# ── DOWNLOAD ──────────────────────────────────────────────────────────────────
print("\n=== DOWNLOADING COMPLETED EXPORTS ===")

downloaded    = []
still_pending = []
failed        = []

for job in pending_jobs:
    sid       = job["scenario_id"]
    export_id = job["export_id"]
    print(f"\n  Scenario : {sid}")
    print(f"  Export   : {export_id}")

    try:
        check = requests.get(
            f"{BASE_URL}/scenario_exports/{export_id}",
            headers=HEADERS
        )
        print(f"  HTTP     : {check.status_code}")

        if check.status_code == 200:
            ok, path = check_and_download_export(export_id, sid)
            if ok:
                log_run(f"/scenarios/{sid}/full_csv", "success", 1, path)
                downloaded.append(sid)
            else:
                # Still in_progress — add back to pending
                still_pending.append(job)

        elif check.status_code == 404:
            # Export expired — re-trigger and queue for next attempt
            print(f"  ⚠ Export expired (404) — re-triggering...")
            retry = requests.get(
                f"{BASE_URL}/scenarios/{sid}/full_csv",
                headers=HEADERS
            )
            if retry.status_code == 200:
                path = land(retry.text, f"scenario_full_csv/{sid}",
                            f"full_csv_{sid}_{TIMESTAMP}.csv")
                log_run(f"/scenarios/{sid}/full_csv", "success-retriggered", 1, path)
                downloaded.append(sid)
                print(f"  ✅ Retrieved directly after re-trigger")
            elif retry.status_code == 202:
                new_id = retry.json().get("background_csv_export")
                print(f"  New export ID: {new_id} — will need another run")
                still_pending.append({"scenario_id": sid, "export_id": new_id})
            else:
                print(f"  ❌ Re-trigger failed: HTTP {retry.status_code}")
                failed.append(job)
                log_run(f"/scenarios/{sid}/full_csv",
                        f"error-retrigger-{retry.status_code}", 0, "")

        else:
            print(f"  ❌ Unexpected HTTP {check.status_code}")
            failed.append(job)
            log_run(f"/scenarios/{sid}/full_csv",
                    f"error-{check.status_code}", 0, "")

    except Exception as e:
        print(f"  ❌ {e}")
        failed.append(job)
        log_run(f"/scenarios/{sid}/full_csv", f"error: {e}", 0, "")

# ── SAVE ANY REMAINING FOR MANUAL RETRY ───────────────────────────────────────
if still_pending:
    save_jobs(still_pending, label="retry_exports")
    print(f"\n⚠ {len(still_pending)} still pending.")
    print(f"  Re-run this notebook manually in 15-30 mins to collect them.")

if failed:
    save_jobs(failed, label="failed_download")

# ── SUMMARY ───────────────────────────────────────────────────────────────────
total = len(downloaded) + len(still_pending) + len(failed)
print(f"\n{'=' * 60}")
print(f"✅ 03_download_exports complete  |  {TIMESTAMP}")
print(f"   Downloaded    : {len(downloaded)} / {total}")
print(f"   Still pending : {len(still_pending)}")
print(f"   Failed        : {len(failed)}")
print(f"{'=' * 60}")
