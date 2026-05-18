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