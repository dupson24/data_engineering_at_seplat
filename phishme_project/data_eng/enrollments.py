print("\n=== 6. ENROLLMENTS ===")

# First try /enrollments (may need read-write token)
# If 401, fall back to engagement-based enrollment data
try:
    resp = requests.get(f"{BASE_URL}/enrollments", headers=HEADERS)
    print(f"  Status: {resp.status_code}")

    if resp.status_code == 401:
        print("  ⚠ /enrollments requires read-write token — skipping")
        print("  ℹ To fix: generate a read-write token in PhishMe and update PhishMe-API-Key in AKV")
        log_run("/enrollments", "skipped — requires read-write token", 0, "")

    elif resp.status_code == 200:
        path = land(resp.text, "enrollments", f"enrollments_{TIMESTAMP}.csv")
        row_count = max(0, len(resp.text.strip().split("\n")) - 4)
        log_run("/enrollments", "success", row_count, path)
        print(f"  Total rows: {row_count}")
    else:
        print(f"  ❌ Unexpected status: {resp.status_code} — {resp.text[:200]}")
        log_run("/enrollments", f"error: {resp.status_code}", 0, "")

except Exception as e:
    print(f"  ❌ {e}")
    log_run("/enrollments", f"error: {e}", 0, "")