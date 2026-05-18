Simple 4-column structure. Using JSON as source of truth:

```python
# ============================================================
# Cell 1 — Imports & Config
# ============================================================
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, lit, current_timestamp, to_timestamp, count, when
from pyspark.sql.types import *
from datetime import datetime, timezone

spark = SparkSession.builder.getOrCreate()

RAW_BASE  = "/mnt/PhishMe/raw"
PROCESSED = "/mnt/PhishMe/processed"
RUN_DATE  = datetime.now(timezone.utc)
DATE_PATH = RUN_DATE.strftime("%Y/%m/%d")
TODAY     = RUN_DATE.strftime("%Y-%m-%d")
```

```python
# ============================================================
# Cell 2 — Schema
# ============================================================
activity_logs_schema = StructType([
    StructField("user",          StringType(), True),
    StructField("activity_name", StringType(), True),
    StructField("date_time",     StringType(), True),
    StructField("ip_address",    StringType(), True),
])
```

```python
# ============================================================
# Cell 3 — Read
# ============================================================
def read_activity_logs_raw(date_path=DATE_PATH):
    path = f"{RAW_BASE}/activity_logs/{date_path}/*.json"
    df = (spark.read
              .option("multiLine", "true")
              .schema(activity_logs_schema)
              .json(path))
    print(f"Raw rows: {df.count()}")
    return df
```

```python
# ============================================================
# Cell 4 — Transform
# ============================================================
def transform_activity_logs(df):
    return (df
        .withColumn("event_timestamp", to_timestamp(col("date_time"), "yyyy-MM-dd HH:mm:ss"))
        .drop("date_time")
        .withColumn("ingested_date", lit(TODAY).cast(DateType()))
        .withColumn("ingested_at",   current_timestamp())
        .dropDuplicates(["user", "activity_name", "event_timestamp"])
        .filter(col("user").isNotNull())
    )
```

```python
# ============================================================
# Cell 5 — Write
# ============================================================
def write_activity_logs_processed(df):
    path = f"{PROCESSED}/activity_logs"
    (df.write
       .format("delta")
       .mode("overwrite")
       .option("overwriteSchema", "true")
       .partitionBy("ingested_date")
       .save(path))
    print(f"✅ Written to: {path}")
    print(f"   Rows: {df.count()}")
```

```python
# ============================================================
# Cell 6 — Run + Display
# ============================================================
raw_df  = read_activity_logs_raw()

print("=== RAW SCHEMA ===")
raw_df.printSchema()
display(raw_df)

proc_df = transform_activity_logs(raw_df)

print("\n=== PROCESSED SCHEMA ===")
proc_df.printSchema()
display(proc_df)

print("\n=== ACTIVITY BREAKDOWN ===")
display(proc_df.groupBy("activity_name").count().orderBy("count", ascending=False))

print("\n=== NULL CHECK ===")
display(proc_df.select([
    count(when(col(c).isNull(), c)).alias(c)
    for c in proc_df.columns
]))

write_activity_logs_processed(proc_df)
```