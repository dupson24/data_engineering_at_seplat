# =============================================================================
# Cofense PhishMe — 00_mount_setup.py
# Workspace : /PhishMe/notebooks/00_mount_setup.py
# Purpose   : One-time mount verification. Run manually, not part of workflow.
# =============================================================================

# Inline — no %run dependency so this always works standalone
MOUNT_POINT      = "/mnt/PhishMe"
STORAGE_ACCOUNT  = "seplatedwstorage"
CONTAINER        = "seplat-security-phishme"
SECRET_SCOPE     = "CorpAvailScope"
STORAGE_SECRET   = "CorpAvailkeys"
API_SECRET_KEY   = "PhishMe-API-Key"

print("=" * 60)
print("PhishMe — Mount & Token Verification")
print("=" * 60)

# ── 1. VERIFY SECRET SCOPE EXISTS ────────────────────────────────────────────
print("\n1. Checking secret scope...")
try:
    token = dbutils.secrets.get(scope=SECRET_SCOPE, key=API_SECRET_KEY)
    print(f"   ✅ Token retrieved | length: {len(token)} chars")
except Exception as e:
    print(f"   ❌ Token error: {e}")

# ── 2. VERIFY STORAGE KEY ────────────────────────────────────────────────────
print("\n2. Checking storage key...")
try:
    storage_key = dbutils.secrets.get(scope=SECRET_SCOPE, key=STORAGE_SECRET)
    print(f"   ✅ Storage key retrieved | length: {len(storage_key)} chars")
except Exception as e:
    print(f"   ❌ Storage key error: {e}")

# ── 3. MOUNT ──────────────────────────────────────────────────────────────────
print("\n3. Mounting ADLS container...")
existing_mounts = [m.mountPoint for m in dbutils.fs.mounts()]

if MOUNT_POINT in existing_mounts:
    print(f"   ✅ Already mounted at {MOUNT_POINT}")
else:
    try:
        dbutils.fs.mount(
            source=f"wasbs://{CONTAINER}@{STORAGE_ACCOUNT}.blob.core.windows.net",
            mount_point=MOUNT_POINT,
            extra_configs={
                f"fs.azure.account.key.{STORAGE_ACCOUNT}.blob.core.windows.net":
                    dbutils.secrets.get(scope=SECRET_SCOPE, key=STORAGE_SECRET)
            }
        )
        print(f"   ✅ Mounted successfully at {MOUNT_POINT}")
    except Exception as e:
        print(f"   ❌ Mount failed: {e}")

# ── 4. VERIFY MOUNT & CREATE FOLDER STRUCTURE ────────────────────────────────
print("\n4. Verifying mount and creating folder structure...")
folders = [
    "_jobs", "_audit_log",
    "users", "scenarios", "scenario_groups",
    "scenario_full_csv", "scenario_activity_timeline",
    "enrollments", "engagement_scores",
    "repeat_clickers", "activity_logs"
]
try:
    for folder in folders:
        path = f"{MOUNT_POINT}/raw/{folder}/.keep"
        dbutils.fs.put(path, "keep", overwrite=True)
    print(f"   ✅ All folders created under {MOUNT_POINT}/raw/")
except Exception as e:
    print(f"   ❌ Folder creation failed: {e}")

# ── 5. API TOKEN TEST ─────────────────────────────────────────────────────────
print("\n5. Testing API token against /users.csv...")
import requests
BASE_URL = "https://login.phishme.co.uk/api/v2"
try:
    token   = dbutils.secrets.get(scope=SECRET_SCOPE, key=API_SECRET_KEY)
    headers = {"Authorization": f'Token token="{token}"'}
    resp    = requests.get(f"{BASE_URL}/users.csv", headers=headers)
    print(f"   HTTP status : {resp.status_code}")
    if resp.status_code == 200:
        lines = resp.text.strip().split("\n")
        print(f"   ✅ API OK — {len(lines) - 1} users returned")
        print(f"   Preview    : {resp.text[:120]}...")
    else:
        print(f"   ❌ API error: {resp.text[:200]}")
except Exception as e:
    print(f"   ❌ {e}")

print("\n" + "=" * 60)
print("Setup complete. Ready to run daily workflow.")
print("=" * 60)
