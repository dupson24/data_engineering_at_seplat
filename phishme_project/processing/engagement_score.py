Two formats landed — CSV and JSON. JSON is richer (has `recipient_id`). We'll use JSON as the source of truth.

```python
# ============================================================
# Cell 1 — Imports & Config
# ============================================================
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, lit, current_timestamp, count, when
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
engagement_schema = StructType([
    StructField("recipient_id",          StringType(), True),
    StructField("email_address",         StringType(), True),
    StructField("proficiency_score",     DoubleType(),  True),
    StructField("scenario_count",        IntegerType(), True),
    StructField("reporting_percent",     DoubleType(),  True),
    StructField("susceptibility_percent",DoubleType(),  True),
])
```

```python
# ============================================================
# Cell 3 — Read JSON (latest file only — deduped daily snapshot)
# ============================================================
def read_engagement_raw(date_path=DATE_PATH):
    path = f"{RAW_BASE}/engagement_scores/{date_path}/*.json"
    df = (spark.read
              .option("multiLine", "true")
              .schema(engagement_schema)
              .json(path))
    print(f"Raw rows: {df.count()}")
    return df
```

```python
# ============================================================
# Cell 4 — Transform
# ============================================================
def transform_engagement(df):
    from pyspark.sql.functions import when as W
    return (df
        .withColumnRenamed("email_address",          "email")
        .withColumnRenamed("proficiency_score",      "proficiency_score")
        .withColumnRenamed("scenario_count",         "scenarios_received")
        .withColumnRenamed("reporting_percent",      "reporting_percent")
        .withColumnRenamed("susceptibility_percent", "susceptibility_percent")
        # Risk banding
        .withColumn("risk_band",
            W(col("susceptibility_percent") >= 75,  lit("High"))
            .when(col("susceptibility_percent") >= 25, lit("Medium"))
            .otherwise(lit("Low")))
        # Proficiency banding
        .withColumn("proficiency_band",
            W(col("proficiency_score") >= 50,   lit("Good"))
            .when(col("proficiency_score") >= 0, lit("Neutral"))
            .otherwise(lit("At Risk")))
        .withColumn("ingested_date", lit(TODAY).cast(DateType()))
        .withColumn("ingested_at",   current_timestamp())
        .dropDuplicates(["recipient_id"])
        .filter(col("email").isNotNull())
    )
```

```python
# ============================================================
# Cell 5 — Write to Processed (Delta)
# ============================================================
def write_engagement_processed(df):
    path = f"{PROCESSED}/engagement_scores"
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
raw_df  = read_engagement_raw()

print("=== RAW SCHEMA ===")
raw_df.printSchema()
display(raw_df.limit(5))

proc_df = transform_engagement(raw_df)

print("\n=== PROCESSED SCHEMA ===")
proc_df.printSchema()
display(proc_df.limit(5))

print("\n=== RISK BAND DISTRIBUTION ===")
display(proc_df.groupBy("risk_band").count().orderBy("count", ascending=False))

print("\n=== PROFICIENCY BAND DISTRIBUTION ===")
display(proc_df.groupBy("proficiency_band").count().orderBy("count", ascending=False))

print("\n=== SCORE STATS ===")
from pyspark.sql.functions import avg, min, max
display(proc_df.agg(
    avg("proficiency_score").alias("avg_proficiency"),
    avg("susceptibility_percent").alias("avg_susceptibility"),
    avg("reporting_percent").alias("avg_reporting"),
    min("proficiency_score").alias("min_proficiency"),
    max("proficiency_score").alias("max_proficiency"),
))

print("\n=== NULL CHECK ===")
display(proc_df.select([
    count(when(col(c).isNull(), c)).alias(c)
    for c in proc_df.columns
]))

write_engagement_processed(proc_df)
```