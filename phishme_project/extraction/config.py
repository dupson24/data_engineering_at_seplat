# =============================================================================
# Cofense PhishMe — Pipeline Configuration
# Workspace : /PhishMe/config/config.py
# Usage     : %run ../config/config  (at top of every notebook)
# =============================================================================

from datetime import datetime, timezone, timedelta

# ── API ───────────────────────────────────────────────────────────────────────
API_SECRET_SCOPE = "CorpAvailScope"
API_SECRET_KEY   = "PhishMe-API-Key"
BASE_URL         = "https://login.phishme.co.uk/api/v2"

# ── AZURE STORAGE ─────────────────────────────────────────────────────────────
STORAGE_ACCOUNT  = "seplatedwstorage"
CONTAINER        = "seplat-security-phishme"
MOUNT_POINT      = "/mnt/PhishMe"
STORAGE_SECRET   = "CorpAvailkeys"          # AKV secret name for storage key

# ── DERIVED PATHS ─────────────────────────────────────────────────────────────
RAW_BASE         = f"{MOUNT_POINT}/raw"
JOBS_PATH        = f"{MOUNT_POINT}/raw/_jobs"
AUDIT_PATH       = f"{MOUNT_POINT}/raw/_audit_log"

# ── RUN WINDOW (recalculated fresh on each %run) ──────────────────────────────
RUN_DATE         = datetime.now(timezone.utc)
DATE_PATH        = RUN_DATE.strftime("%Y/%m/%d")
TIMESTAMP        = RUN_DATE.strftime("%Y%m%dT%H%M%SZ")
TODAY            = RUN_DATE.strftime("%Y-%m-%d")
YESTERDAY        = (RUN_DATE - timedelta(days=1)).strftime("%Y-%m-%d")
HISTORY_START    = "2024-01-01"             # start of historical pull window

# ── EXPORT TUNING ─────────────────────────────────────────────────────────────
RATE_LIMIT_BUFFER    = 5                    # extra seconds added after rate-limit wait
EXPORT_POLL_SLEEP    = 30                   # seconds between export status checks (03)
EXPORT_MAX_WAIT      = 900                  # max wait per export in seconds (03)
