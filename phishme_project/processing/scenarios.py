from pyspark.sql import SparkSession
from pyspark.sql.functions import col, lit, current_timestamp, to_date
from pyspark.sql.types import *
from datetime import datetime, timezone
from pyspark.sql.functions import count, when, isnan

spark = SparkSession.builder.getOrCreate()

RAW_BASE   = "/mnt/PhishMe/raw"
SILVER_BASE= "/mnt/PhishMe/processed"
RUN_DATE   = datetime.now(timezone.utc)
DATE_PATH  = RUN_DATE.strftime("%Y/%m/%d")
TODAY      = RUN_DATE.strftime("%Y-%m-%d")

```python
# ============================================================
# Cell 7 — Scenarios Schema
# ============================================================
scenarios_schema = StructType([
    StructField("id",                    StringType(),  True),
    StructField("name",                  StringType(),  True),
    StructField("status",                StringType(),  True),
    StructField("scenario_type",         StringType(),  True),
    StructField("created_at",            StringType(),  True),
    StructField("updated_at",            StringType(),  True),
    StructField("starts_at",             StringType(),  True),
    StructField("ends_at",               StringType(),  True),
    StructField("duration_days",         IntegerType(), True),
    StructField("total_recipients",      IntegerType(), True),
    StructField("emails_sent",           IntegerType(), True),
    StructField("emails_reported",       IntegerType(), True),
    StructField("emails_clicked",        IntegerType(), True),
    StructField("emails_opened",         IntegerType(), True),
    StructField("attachments_opened",    IntegerType(), True),
    StructField("data_entered",          IntegerType(), True),
    StructField("scenario_group_id",     StringType(),  True),
    StructField("scenario_group_name",   StringType(),  True),
])
```

```python
# ============================================================
# Cell 8 — Read Raw Scenarios JSON
# ============================================================
def read_scenarios_raw(date_path=DATE_PATH):
    path = f"{RAW_BASE}/scenarios/{date_path}/"
    df = (spark.read
              .option("multiLine", "true")
              .schema(scenarios_schema)
              .json(path))
    print(f"Raw rows: {df.count()}")
    return df
```

```python
# ============================================================
# Cell 9 — Transform
# ============================================================
def transform_scenarios(df):
    from pyspark.sql.functions import to_timestamp
    return (df
        .withColumn("created_at",    to_timestamp(col("created_at")))
        .withColumn("updated_at",    to_timestamp(col("updated_at")))
        .withColumn("starts_at",     to_timestamp(col("starts_at")))
        .withColumn("ends_at",       to_timestamp(col("ends_at")))
        .withColumn("is_active",     col("status").isin("active", "in_progress"))
        .withColumn("ingested_date", lit(TODAY).cast(DateType()))
        .withColumn("ingested_at",   current_timestamp())
        .dropDuplicates(["id"])
        .filter(col("id").isNotNull())
    )
```

```python
# ============================================================
# Cell 10 — Write to Processed (Delta)
# ============================================================
def write_scenarios_processed(df):
    path = f"{SILVER_BASE}/scenarios"
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
# Cell 11 — Run + Display
# ============================================================
raw_sc     = read_scenarios_raw()

print("=== RAW SCHEMA ===")
raw_sc.printSchema()
display(raw_sc)

silver_sc  = transform_scenarios(raw_sc)

print("\n=== PROCESSED SCHEMA ===")
silver_sc.printSchema()
display(silver_sc)

print("\n=== STATUS BREAKDOWN ===")
display(silver_sc.groupBy("status", "is_active").count())

print("\n=== NULL CHECK ===")
display(silver_sc.select([
    count(when(col(c).isNull(), c)).alias(c)
    for c in silver_sc.columns
]))

write_scenarios_processed(silver_sc)
```

Run Cell 11 and share output — we'll adjust the schema if any fields come back null or mistyped, then move to scenario groups.