First inspect the file:

```python
# ============================================================
# Cell 1 — Inspect
# ============================================================
from datetime import datetime, timezone

RAW_BASE  = "/mnt/PhishMe/raw"
PROCESSED = "/mnt/PhishMe/processed"
RUN_DATE  = datetime.now(timezone.utc)
DATE_PATH = RUN_DATE.strftime("%Y/%m/%d")
TODAY     = RUN_DATE.strftime("%Y-%m-%d")

path = f"{RAW_BASE}/engagement_scores/{DATE_PATH}/"
for f in dbutils.fs.ls(path):
    print(f"File : {f.name}")
    print(f"Size : {f.size} bytes")
    print(f"Preview:\n{dbutils.fs.head(f.path, 3000)}")
    print("---")
```

Share the output and we'll build the full notebook.