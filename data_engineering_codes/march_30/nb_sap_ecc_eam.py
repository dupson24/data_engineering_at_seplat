# =============================================================================
# NOTEBOOK : Discovery — sap-ecc-eam
# PROJECT  : Seplat Energy EDW  |  SAP ECC → Datasphere → ADLS Gen2
# AUTHOR   : Funke Yusuf  |  Wragby Solutions
# PURPOSE  : Auto-detect all Parquet tables under the sap-ecc-eam ADLS path,
#            infer structure (flat / partitioned / nested), print schema and
#            row counts. NO data is written — discovery mode only.
# =============================================================================

# -----------------------------------------------------------------------------
# CELL 1 — Parameters  (edit STORAGE_ACCOUNT only)
# -----------------------------------------------------------------------------
# Databricks widget for runtime override
dbutils.widgets.text("storage_account", "YOUR_STORAGE_ACCOUNT", "Storage Account Name")
dbutils.widgets.text("max_depth",       "4",                    "Max folder depth to scan")

STORAGE_ACCOUNT = dbutils.widgets.get("storage_account")
MAX_DEPTH       = int(dbutils.widgets.get("max_depth"))

CONTAINER   = "sap-ecc-datasphere"
BASE_PATH   = "sap-ecc-eam"
ABFSS_ROOT  = f"abfss://{CONTAINER}@{STORAGE_ACCOUNT}.dfs.core.windows.net/{BASE_PATH}"

print(f"Root path : {ABFSS_ROOT}")
print(f"Max depth : {MAX_DEPTH}")

# -----------------------------------------------------------------------------
# CELL 2 — Mount / Auth check
#           Uses the cluster's service-principal / managed-identity credential
#           already configured in Databricks.  No extra config needed if the
#           cluster has ADLS access via cluster policy or Unity Catalog.
# -----------------------------------------------------------------------------
try:
    files = dbutils.fs.ls(ABFSS_ROOT)
    print(f"✅  Root accessible — {len(files)} top-level entries found")
except Exception as e:
    raise RuntimeError(
        f"❌  Cannot access {ABFSS_ROOT}.\n"
        f"    Check: storage account name, container name, cluster credential.\n"
        f"    Error: {e}"
    )

# -----------------------------------------------------------------------------
# CELL 3 — Recursive folder walker + Parquet detector
# -----------------------------------------------------------------------------
from collections import defaultdict

def walk(path: str, depth: int = 0) -> list[dict]:
    """
    Recursively walk ADLS path up to MAX_DEPTH.
    Returns list of dicts: {table_path, table_name, has_parquet, depth, partition_cols}
    """
    if depth > MAX_DEPTH:
        return []

    results = []
    try:
        entries = dbutils.fs.ls(path)
    except Exception:
        return []

    # Check if THIS folder contains parquet files directly
    parquet_files = [e for e in entries if e.name.endswith(".parquet") or e.name.endswith(".snappy.parquet")]
    subdirs       = [e for e in entries if e.isDir()]

    if parquet_files:
        # Detect partition columns from subfolder naming (e.g. year=2024/month=01)
        partition_cols = _detect_partition_cols(path)
        results.append({
            "table_path"     : path,
            "table_name"     : _infer_table_name(path, ABFSS_ROOT),
            "has_parquet"    : True,
            "depth"          : depth,
            "partition_cols" : partition_cols,
            "file_count"     : len(parquet_files),
        })
    else:
        # Walk into subdirectories
        for sub in subdirs:
            results.extend(walk(sub.path, depth + 1))

    return results


def _infer_table_name(path: str, root: str) -> str:
    """Strip root and partition segments to get a clean table name."""
    relative = path.replace(root, "").strip("/")
    # Remove partition segments like year=2024/month=01
    parts = [p for p in relative.split("/") if "=" not in p and p]
    return "/".join(parts) if parts else relative


def _detect_partition_cols(path: str) -> list[str]:
    """
    Look at immediate subdirs of a parquet folder to identify
    Hive-style partition columns (col=value).
    """
    try:
        children = dbutils.fs.ls(path)
        cols = []
        for c in children:
            if c.isDir() and "=" in c.name:
                col = c.name.split("=")[0]
                if col not in cols:
                    cols.append(col)
        return cols
    except Exception:
        return []


print("🔍  Scanning for Parquet tables...")
discovered = walk(ABFSS_ROOT)
print(f"✅  Discovery complete — {len(discovered)} Parquet table location(s) found\n")

# -----------------------------------------------------------------------------
# CELL 4 — Display discovery summary (before reading schemas)
# -----------------------------------------------------------------------------
from pyspark.sql.functions import lit
import pandas as pd

summary_rows = []
for t in discovered:
    summary_rows.append({
        "table_name"    : t["table_name"],
        "depth"         : t["depth"],
        "file_count"    : t["file_count"],
        "partition_cols": ", ".join(t["partition_cols"]) if t["partition_cols"] else "(none — flat)",
        "path"          : t["table_path"],
    })

summary_pdf = pd.DataFrame(summary_rows)
print("=" * 90)
print(f"  SAP-ECC-EAM  |  Discovered Tables ({len(discovered)})")
print("=" * 90)
display(spark.createDataFrame(summary_pdf))

# -----------------------------------------------------------------------------
# CELL 5 — Schema + Row Count per table
# -----------------------------------------------------------------------------
from pyspark.sql import DataFrame
from pyspark.sql.utils import AnalysisException

def read_parquet_safe(path: str, partition_cols: list[str]) -> DataFrame | None:
    """Read parquet, handling both flat and partitioned layouts."""
    try:
        if partition_cols:
            # Use root path — Spark will infer partition schema automatically
            df = spark.read.option("mergeSchema", "true").parquet(path)
        else:
            df = spark.read.option("mergeSchema", "true").parquet(f"{path}/*.parquet")
        return df
    except AnalysisException:
        try:
            # Fallback: glob all parquet files recursively
            return spark.read.option("mergeSchema", "true").parquet(path)
        except Exception as e:
            print(f"  ⚠️  Could not read {path}: {e}")
            return None


print("\n" + "=" * 90)
print("  SCHEMA & ROW COUNT PER TABLE")
print("=" * 90)

report = []

for t in discovered:
    tname = t["table_name"] or t["table_path"].split("/")[-1]
    print(f"\n{'─'*80}")
    print(f"  TABLE  : {tname}")
    print(f"  PATH   : {t['table_path']}")
    print(f"  DEPTH  : {t['depth']}  |  FILES: {t['file_count']}  |  PARTITIONS: {', '.join(t['partition_cols']) or 'none'}")
    print(f"{'─'*80}")

    df = read_parquet_safe(t["table_path"], t["partition_cols"])

    if df is None:
        print("  ❌  Skipped (read error)")
        report.append({**t, "row_count": -1, "col_count": -1, "schema": "ERROR"})
        continue

    row_count = df.count()
    col_count = len(df.columns)
    schema_str = "\n".join(
        f"    {f.name:<40} {str(f.dataType):<30} nullable={f.nullable}"
        for f in df.schema.fields
    )

    print(f"  ROWS   : {row_count:,}")
    print(f"  COLS   : {col_count}")
    print(f"\n  SCHEMA :")
    print(schema_str)

    # Show sample nulls per column
    print(f"\n  NULL COUNTS (top 10 cols):")
    from pyspark.sql.functions import col, count, when, isnan
    null_counts = df.select([
        count(when(col(c).isNull(), c)).alias(c)
        for c in df.columns[:10]
    ])
    display(null_counts)

    report.append({
        **t,
        "row_count" : row_count,
        "col_count" : col_count,
        "schema"    : schema_str,
    })

# -----------------------------------------------------------------------------
# CELL 6 — Final consolidated report
# -----------------------------------------------------------------------------
print("\n" + "=" * 90)
print("  FINAL DISCOVERY REPORT  —  sap-ecc-eam")
print("=" * 90)

final_pdf = pd.DataFrame([{
    "table_name"    : r["table_name"],
    "row_count"     : r["row_count"],
    "col_count"     : r["col_count"],
    "partition_cols": ", ".join(r["partition_cols"]) if r["partition_cols"] else "flat",
    "file_count"    : r["file_count"],
    "depth"         : r["depth"],
    "path"          : r["table_path"],
} for r in report])

display(spark.createDataFrame(final_pdf))

print(f"\n✅  sap-ecc-eam discovery complete.")
print(f"    Total tables : {len(report)}")
print(f"    Total rows   : {sum(r['row_count'] for r in report if r['row_count'] > 0):,}")
print(f"    Errors       : {sum(1 for r in report if r['row_count'] == -1)}")