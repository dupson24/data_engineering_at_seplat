# =============================================================================
# NOTEBOOK : Discovery — sap-ecc-datasphere / sap-ecc-eam / eam-wf-and-invoices
# PROJECT  : Seplat Energy EDW  |  SAP ECC → Datasphere → Azure
# AUTHOR   : Funke Yusuf  |  Wragby Solutions
# CONTAINER: sap-ecc-datasphere
# FOLDER   : sap-ecc-eam/eam-wf-and-invoices
# PURPOSE  : Mount container, auto-detect all Parquet tables under the folder,
#            print schema + row counts. NO data written — discovery only.
# =============================================================================


# ─────────────────────────────────────────────────────────────────────────────
# CELL 1 — Configuration
# ─────────────────────────────────────────────────────────────────────────────

STORAGE_ACCOUNT = "seplatedwstorage"
CONTAINER       = "sap-ecc-datasphere"
SECRET_SCOPE    = "CorpAvailScope"
SECRET_KEY      = "CorpAvailkeys"
MAX_DEPTH       = 4

# Blob source — full container
blobfolder  = f"wasbs://{CONTAINER}@{STORAGE_ACCOUNT}.blob.core.windows.net"
mount_point = f"/mnt/{CONTAINER}"

# Target folder to scan inside the mounted container
SCAN_FOLDER = f"{mount_point}/sap-ecc-eam/eam-wf-and-invoices"

print("=" * 70)
print("  Seplat EDW — Parquet Discovery")
print("=" * 70)
print(f"  Storage account : {STORAGE_ACCOUNT}")
print(f"  Container       : {CONTAINER}")
print(f"  Blob source     : {blobfolder}")
print(f"  Mount point     : {mount_point}")
print(f"  Scan target     : {SCAN_FOLDER}")


# ─────────────────────────────────────────────────────────────────────────────
# CELL 2 — Mount the container
# ─────────────────────────────────────────────────────────────────────────────

existing_mounts = [m.mountPoint for m in dbutils.fs.mounts()]
print("\nExisting mounts:", existing_mounts)

if mount_point not in existing_mounts:
    try:
        dbutils.fs.mount(
            source      = blobfolder,
            mount_point = mount_point,
            extra_configs = {
                "fs.azure.account.key.seplatedwstorage.blob.core.windows.net":
                    dbutils.secrets.get(scope="CorpAvailScope", key="CorpAvailkeys")
            }
        )
        print(f"✅ Mounted successfully at {mount_point}")
    except Exception as e:
        print(f"❌ Error mounting {mount_point}: {e}")
        raise
else:
    print(f"Already mounted at {mount_point}")

# ── Verify the exact folder path exists ──────────────────────────────────────
try:
    top_entries = dbutils.fs.ls(SCAN_FOLDER)
    print(f"\n✅ Scan folder accessible — {len(top_entries)} top-level entries found")
    print("\nTop-level contents:")
    for e in top_entries:
        kind = "DIR " if e.isDir() else "FILE"
        print(f"  [{kind}]  {e.name}  ({e.size:,} bytes)" if not e.isDir() else f"  [{kind}]  {e.name}")
except Exception as e:
    raise RuntimeError(
        f"\n❌ Cannot access: {SCAN_FOLDER}\n"
        f"   Verify the folder path exists inside the container.\n"
        f"   Error: {e}"
    )


# ─────────────────────────────────────────────────────────────────────────────
# CELL 3 — Recursive Parquet walker
# ─────────────────────────────────────────────────────────────────────────────

def walk(path: str, root: str, depth: int = 0) -> list:
    """
    Recursively scan for Parquet files up to MAX_DEPTH.
    Skips Spark/Delta metadata folders (_delta_log, _SUCCESS, etc.)
    Returns list of table descriptor dicts.
    """
    if depth > MAX_DEPTH:
        return []

    results = []
    try:
        entries = dbutils.fs.ls(path)
    except Exception:
        return []

    parquet_files = [
        e for e in entries
        if not e.isDir()
        and (e.name.endswith(".parquet") or e.name.endswith(".snappy.parquet"))
    ]
    subdirs = [
        e for e in entries
        if e.isDir()
        and not e.name.startswith("_")
        and not e.name.startswith(".")
    ]

    if parquet_files:
        partition_cols = _detect_partition_cols(path)
        results.append({
            "table_path"     : path,
            "table_name"     : _infer_table_name(path, root),
            "depth"          : depth,
            "file_count"     : len(parquet_files),
            "partition_cols" : partition_cols,
        })
    else:
        for sub in subdirs:
            results.extend(walk(sub.path, root, depth + 1))

    return results


def _infer_table_name(path: str, root: str) -> str:
    """
    Strip root scan path + any Hive partition segments.
    e.g. .../eam-wf-and-invoices/RBKP/year=2024  →  RBKP
    """
    relative = path.replace(root, "").strip("/")
    parts    = [p for p in relative.split("/") if "=" not in p and p]
    return "/".join(parts) if parts else "(root)"


def _detect_partition_cols(path: str) -> list:
    """
    Detect Hive-style partition columns from child folder names.
    e.g. GJAHR=2024 → ['GJAHR'] | year=2024/month=01 → ['year', 'month']
    """
    try:
        cols = []
        for c in dbutils.fs.ls(path):
            if c.isDir() and "=" in c.name:
                col = c.name.split("=")[0]
                if col not in cols:
                    cols.append(col)
        return cols
    except Exception:
        return []


# ─────────────────────────────────────────────────────────────────────────────
# CELL 4 — Run discovery
# ─────────────────────────────────────────────────────────────────────────────

print(f"\n🔍  Scanning: {SCAN_FOLDER}\n")
discovered = walk(SCAN_FOLDER, SCAN_FOLDER)
print(f"✅  Discovery complete — {len(discovered)} Parquet table(s) found")


# ─────────────────────────────────────────────────────────────────────────────
# CELL 5 — Summary table
# ─────────────────────────────────────────────────────────────────────────────

import pandas as pd

summary_rows = [
    {
        "table_name"    : t["table_name"],
        "file_count"    : t["file_count"],
        "partition_cols": ", ".join(t["partition_cols"]) if t["partition_cols"] else "flat",
        "depth"         : t["depth"],
        "path"          : t["table_path"],
    }
    for t in discovered
]

print("\n" + "=" * 90)
print(f"  DISCOVERY SUMMARY")
print(f"  Container : {CONTAINER}")
print(f"  Folder    : sap-ecc-eam/eam-wf-and-invoices")
print(f"  Tables    : {len(discovered)}")
print("=" * 90)
display(spark.createDataFrame(pd.DataFrame(summary_rows)))


# ─────────────────────────────────────────────────────────────────────────────
# CELL 6 — Schema + Row Count per table
# ─────────────────────────────────────────────────────────────────────────────

from pyspark.sql.utils import AnalysisException
from pyspark.sql.functions import col, count, when


def read_parquet_safe(path: str, partition_cols: list):
    """
    Read Parquet from mounted path.
    - Partitioned tables : read at root, Spark infers partition schema
    - Flat tables        : glob *.parquet in folder
    - Fallback           : recursive read on root path
    mergeSchema=true handles column drift across part files.
    """
    try:
        if partition_cols:
            return spark.read.option("mergeSchema", "true").parquet(path)
        else:
            return spark.read.option("mergeSchema", "true").parquet(f"{path}/*.parquet")
    except AnalysisException:
        try:
            return spark.read.option("mergeSchema", "true").parquet(path)
        except Exception as e:
            print(f"  ⚠️  Read failed: {e}")
            return None


report = []

print("\n" + "=" * 90)
print("  SCHEMA & ROW COUNT PER TABLE")
print("=" * 90)

for t in discovered:
    tname = t["table_name"] or t["table_path"].split("/")[-1]
    parts = ", ".join(t["partition_cols"]) if t["partition_cols"] else "none (flat)"

    print(f"\n{'─' * 80}")
    print(f"  TABLE      : {tname}")
    print(f"  PATH       : {t['table_path']}")
    print(f"  FILES      : {t['file_count']}   DEPTH: {t['depth']}   PARTITIONS: {parts}")
    print(f"{'─' * 80}")

    df = read_parquet_safe(t["table_path"], t["partition_cols"])

    if df is None:
        print("  ❌  Skipped — could not read")
        report.append({**t, "row_count": -1, "col_count": -1})
        continue

    row_count = df.count()
    col_count = len(df.columns)

    print(f"  ROWS       : {row_count:,}")
    print(f"  COLUMNS    : {col_count}")
    print(f"\n  SCHEMA:")
    for f in df.schema.fields:
        print(f"    {f.name:<40} {str(f.dataType):<25} nullable={f.nullable}")

    # Null counts — first 10 columns
    print(f"\n  NULL COUNTS (first 10 columns):")
    null_df = df.select([
        count(when(col(c).isNull(), c)).alias(c)
        for c in df.columns[:10]
    ])
    display(null_df)

    # EAM / Invoice pattern — group by fiscal year if column present
    fy_col = next(
        (c for c in df.columns if c.upper() in ("GJAHR", "FISCAL_YEAR", "BUDAT", "BLDAT", "AEDAT")),
        None
    )
    if fy_col:
        print(f"\n  📅  Date/Fiscal column detected: '{fy_col}' — row distribution:")
        display(df.groupBy(fy_col).count().orderBy(fy_col))

    report.append({**t, "row_count": row_count, "col_count": col_count})


# ─────────────────────────────────────────────────────────────────────────────
# CELL 7 — Final consolidated report
# ─────────────────────────────────────────────────────────────────────────────

final_pdf = pd.DataFrame([
    {
        "table_name"    : r["table_name"],
        "row_count"     : f"{r['row_count']:,}" if r["row_count"] >= 0 else "ERROR",
        "col_count"     : r["col_count"],
        "partition_cols": ", ".join(r["partition_cols"]) if r["partition_cols"] else "flat",
        "file_count"    : r["file_count"],
        "path"          : r["table_path"],
    }
    for r in report
])

print("\n" + "=" * 90)
print("  FINAL DISCOVERY REPORT")
print(f"  Container : {CONTAINER}  |  Folder: sap-ecc-eam/eam-wf-and-invoices")
print("=" * 90)
display(spark.createDataFrame(final_pdf))

total_rows = sum(r["row_count"] for r in report if r["row_count"] >= 0)
errors     = sum(1 for r in report if r["row_count"] < 0)

print(f"\n  ✅  Discovery complete")
print(f"      Tables scanned : {len(report)}")
print(f"      Total rows     : {total_rows:,}")
print(f"      Read errors    : {errors}")


# ─────────────────────────────────────────────────────────────────────────────
# CELL 8 — Optional: unmount when done
# ─────────────────────────────────────────────────────────────────────────────

# Uncomment to unmount after discovery session
# dbutils.fs.unmount(mount_point)
# print(f"Unmounted {mount_point}")