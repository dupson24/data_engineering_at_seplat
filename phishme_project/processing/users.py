```python
# ============================================================
# Cell 1 — Imports & Config
# ============================================================
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, lit, current_timestamp, to_date
from pyspark.sql.types import *
from datetime import datetime, timezone

spark = SparkSession.builder.getOrCreate()

RAW_BASE   = "/mnt/PhishMe/raw"
SILVER_BASE= "/mnt/PhishMe/processed"
RUN_DATE   = datetime.now(timezone.utc)
DATE_PATH  = RUN_DATE.strftime("%Y/%m/%d")
TODAY      = RUN_DATE.strftime("%Y-%m-%d")
```

```python
# ============================================================
# Cell 2 — Users Schema
# ============================================================
users_schema = StructType([
    StructField("Email",           StringType(), True),
    StructField("Name",            StringType(), True),
    StructField("Title",           StringType(), True),
    StructField("Phone",           StringType(), True),
    StructField("Time Zone",       StringType(), True),
    StructField("Roles",           StringType(), True),
    StructField("Deactivated At",  StringType(), True),
])
```

```python
# ============================================================
# Cell 3 — Read raw CSV
# ============================================================
def read_users_raw(date_path=DATE_PATH):
    path = f"{RAW_BASE}/users/{date_path}/"
    df = (spark.read
              .option("header", "true")
              .option("quote", '"')
              .option("escape", '"')
              .option("multiLine", "true")
              .schema(users_schema)
              .csv(path))
    print(f"Raw rows: {df.count()}")
    return df
```

```python
# ============================================================
# Cell 4 — Transform
# ============================================================
def transform_users(df):
    return (df
        .withColumnRenamed("Email",          "email")
        .withColumnRenamed("Name",           "name")
        .withColumnRenamed("Title",          "title")
        .withColumnRenamed("Phone",          "phone")
        .withColumnRenamed("Time Zone",      "time_zone")
        .withColumnRenamed("Roles",          "roles")
        .withColumnRenamed("Deactivated At", "deactivated_at")
        .withColumn("is_active",     col("deactivated_at").isNull())
        .withColumn("ingested_date", lit(TODAY).cast(DateType()))
        .withColumn("ingested_at",   current_timestamp())
        .dropDuplicates(["email"])
        .filter(col("email").isNotNull())
    )
```

```python
# ============================================================
# Cell 5 — Write to Silver (Delta)
# ============================================================
def write_users_silver(df):
    path = f"{SILVER_BASE}/users"
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
# Cell 6 — Run
# ============================================================
raw_df      = read_users_raw()
silver_df   = transform_users(raw_df)
silver_df.show(5, truncate=False)
write_users_silver(silver_df)
```

Run Cell 6 and share the output — once users is confirmed we'll add the next entity.