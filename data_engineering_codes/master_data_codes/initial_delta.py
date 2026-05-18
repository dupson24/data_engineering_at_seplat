# ============================================================
# STEP 2 — Read Bronze (initial + delta)
# ============================================================
from pyspark.sql import functions as F

def read_table(table_name):
    """Read initial + delta and union, return combined df."""
    # Read initial
    initial = (spark.read
        .option("recursiveFileLookup", "true")
        .option("mergeSchema", "true")
        .parquet(f"{raw_path}/{table_name}/initial"))
    print(f"{table_name} initial rows: {initial.count():,}")

    # Read delta if files exist
    try:
        files = dbutils.fs.ls(f"{raw_path}/{table_name}/delta")
        parquet_files = [f for f in files if f.name.endswith(".parquet")]
        if parquet_files:
            delta = (spark.read
                .option("recursiveFileLookup", "true")
                .option("mergeSchema", "true")
                .parquet(f"{raw_path}/{table_name}/delta"))
            print(f"{table_name} delta   rows: {delta.count():,}")
            combined = initial.unionByName(delta)
        else:
            print(f"{table_name} delta   — no parquet files yet")
            combined = initial
    except Exception as e:
        print(f"{table_name} delta   — not available: {e}")
        combined = initial

    print(f"{table_name} combined rows: {combined.count():,}")
    return combined

# Read all three tables
lfa1 = read_table("LFA1")

try:
    lfm1 = read_table("LFM1")
except Exception as e:
    print(f"LFM1 not available: {e}")
    lfm1 = None

try:
    lfm2 = read_table("LFM2")
except Exception as e:
    print(f"LFM2 not available: {e}")
    lfm2 = None