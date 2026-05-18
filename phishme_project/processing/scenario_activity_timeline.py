```python
# ============================================================
# Cell 1 — Imports & Config
# ============================================================
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, lit, current_timestamp, to_timestamp, count, when, regexp_extract
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
timeline_schema = StructType([
    StructField("Timestamp",              StringType(), True),
    StructField("Action",                 StringType(), True),
    StructField("Tracking ID",            StringType(), True),
    StructField("Recipient",              StringType(), True),
    StructField("Group",                  StringType(), True),
    StructField("Remote IP",              StringType(), True),
    StructField("Country",                StringType(), True),
    StructField("City",                   StringType(), True),
    StructField("ISP",                    StringType(), True),
    StructField("Browser",                StringType(), True),
    StructField("User-Agent String",      StringType(), True),
    StructField("Mobile?",                StringType(), True),
    StructField("Email Client?",          StringType(), True),
    StructField("In User Agents charts?", StringType(), True),
])
```

```python
# ============================================================
# Cell 3 — Read (skip 4 comment lines, wildcard all UUIDs)
# ============================================================
def read_timeline_raw(date_path=DATE_PATH):
    path = f"{RAW_BASE}/scenario_activity_timeline/*/{date_path}/"
    df = (spark.read
              .option("header", "true")
              .option("comment", "#")       # skips all # header lines
              .option("quote", '"')
              .option("escape", '"')
              .option("multiLine", "true")
              .option("encoding", "UTF-8")
              .schema(timeline_schema)
              .csv(path))
    df = df.withColumn("source_file", col("_metadata.file_path"))
    print(f"Raw rows: {df.count()}")
    return df
```

```python
# ============================================================
# Cell 4 — Transform
# ============================================================
def transform_timeline(df):
    return (df
        .withColumn("scenario_id",
            regexp_extract(col("source_file"),
                r"scenario_activity_timeline/([^/]+)/", 1))
        .withColumnRenamed("Timestamp",              "event_timestamp")
        .withColumnRenamed("Action",                 "action")
        .withColumnRenamed("Tracking ID",            "tracking_id")
        .withColumnRenamed("Recipient",              "email")
        .withColumnRenamed("Group",                  "recipient_group")
        .withColumnRenamed("Remote IP",              "remote_ip")
        .withColumnRenamed("Country",                "country")
        .withColumnRenamed("City",                   "city")
        .withColumnRenamed("ISP",                    "isp")
        .withColumnRenamed("Browser",                "browser")
        .withColumnRenamed("User-Agent String",      "user_agent")
        .withColumnRenamed("Mobile?",                "is_mobile")
        .withColumnRenamed("Email Client?",          "is_email_client")
        .withColumnRenamed("In User Agents charts?", "in_ua_charts")
        .withColumn("event_timestamp", to_timestamp(col("event_timestamp"), "M/d/yyyy HH:mm:ss"))
        .withColumn("is_mobile",       col("is_mobile") == "1")
        .withColumn("is_email_client", col("is_email_client") == "1")
        .withColumn("in_ua_charts",    col("in_ua_charts") == "1")
        .withColumn("ingested_date",   lit(TODAY).cast(DateType()))
        .withColumn("ingested_at",     current_timestamp())
        .drop("source_file")
        .filter(col("email").isNotNull())
        .filter(col("action").isNotNull())
    )
```

```python
# ============================================================
# Cell 5 — Write to Processed (Delta)
# ============================================================
def write_timeline_processed(df):
    path = f"{PROCESSED}/scenario_activity_timeline"
    (df.write
       .format("delta")
       .mode("overwrite")
       .option("overwriteSchema", "true")
       .partitionBy("ingested_date", "scenario_id")
       .save(path))
    print(f"✅ Written to: {path}")
    print(f"   Rows: {df.count()}")
```

```python
# ============================================================
# Cell 6 — Run + Display
# ============================================================
raw_df  = read_timeline_raw()

print("=== RAW SCHEMA ===")
raw_df.printSchema()
display(raw_df.limit(5))

proc_df = transform_timeline(raw_df)

print("\n=== PROCESSED SCHEMA ===")
proc_df.printSchema()
display(proc_df.limit(5))

print("\n=== ACTION BREAKDOWN ===")
display(proc_df.groupBy("action").count().orderBy("count", ascending=False))

print("\n=== ACTIONS PER SCENARIO ===")
display(proc_df.groupBy("scenario_id", "action").count().orderBy("scenario_id", "count"))

print("\n=== TOP COUNTRIES ===")
display(proc_df.groupBy("country").count().orderBy("count", ascending=False).limit(10))

print("\n=== NULL CHECK ===")
display(proc_df.select([
    count(when(col(c).isNull(), c)).alias(c)
    for c in proc_df.columns
]))

write_timeline_processed(proc_df)
```