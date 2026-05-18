```python
# ============================================================
# Supplier Details — Bronze → Silver → Conformed
# LFA1 + LFM1 + LFM2 → EAM.Supplier_Details
# ============================================================

raw_path       = "/mnt/sap-ecc-datasphere/sap-ecc-raw"
curated_path   = "/mnt/sap-ecc-datasphere/sap-ecc-curated"
conformed_path = "/mnt/sap-ecc-datasphere/sap-ecc-conformed/eam"
```

```python
# ============================================================
# STEP 1 — Check files exist
# ============================================================
for table in ["LFA1", "LFM1", "LFM2"]:
    try:
        files = dbutils.fs.ls(f"{raw_path}/{table}/initial")
        print(f"\n{table} — {len(files)} files")
        for f in files:
            print(f"  {f.name}  |  {f.size:,} bytes")
    except Exception as e:
        print(f"\n{table} — NOT FOUND: {e}")
```

```python
# ============================================================
# STEP 2 — Read Bronze
# ============================================================
from pyspark.sql import functions as F

lfa1 = spark.read.option("recursiveFileLookup", "true").parquet(f"{raw_path}/LFA1/initial")
lfa1_delta = spark.read.option("recursiveFileLookup", "true").parquet(f"{raw_path}/LFA1/delta") if dbutils.fs.ls(f"{raw_path}/LFA1/delta") else None

print(f"LFA1  rows: {lfa1.count():,}  cols: {len(lfa1.columns)}")
print(f"LFA1  columns: {lfa1.columns}")

try:
    lfm1 = spark.read.option("recursiveFileLookup", "true").parquet(f"{raw_path}/LFM1/initial")
    print(f"LFM1  rows: {lfm1.count():,}  cols: {len(lfm1.columns)}")
except:
    print("LFM1 — not available, will use LFA1 only")
    lfm1 = None

try:
    lfm2 = spark.read.option("recursiveFileLookup", "true").parquet(f"{raw_path}/LFM2/initial")
    print(f"LFM2  rows: {lfm2.count():,}  cols: {len(lfm2.columns)}")
except:
    print("LFM2 — not available, will use LFA1 only")
    lfm2 = None
```

```python
# ============================================================
# STEP 3 — Inspect columns
# ============================================================
print("LFA1 columns:", lfa1.columns)
if lfm1: print("LFM1 columns:", lfm1.columns)
if lfm2: print("LFM2 columns:", lfm2.columns)

lfa1.show(5, truncate=False)
```

```python
# ============================================================
# STEP 4 — Silver: cleanse LFA1 (primary source)
# ============================================================
lfa1_clean = (lfa1
    .filter(F.col("MANDT") == "010")
    .dropDuplicates(["LIFNR"])
    .select(
        F.col("LIFNR"),          # Supplier code
        F.col("NAME1"),          # Supplier name
        F.col("TELF1"),          # Phone
        F.col("TELFX"),          # Fax
        F.col("STRAS"),          # Street address
        F.col("ORT01"),          # City
        F.col("LAND1"),          # Country
        F.col("REGIO"),          # Region
        F.col("PSTLZ"),          # Postal code
        F.col("SPERR"),          # Block indicator
        F.col("KTOKK"),          # Account group
        F.col("STCD1"),          # Tax number 1
        F.col("STCEG"),          # VAT number
        *[F.col(c) for c in ["SMTP_ADDR","ANSPK","LIFNR2"]
          if c in lfa1.columns]
    )
)

print(f"LFA1 clean rows: {lfa1_clean.count():,}")
```

```python
# ============================================================
# STEP 5 — Silver: cleanse LFM1 if available
# ============================================================
if lfm1:
    lfm1_clean = (lfm1
        .filter(F.col("MANDT") == "010")
        .dropDuplicates(["LIFNR","EKORG"])
        .select(
            F.col("LIFNR"),
            F.col("EKORG"),       # Purchasing org
            *[F.col(c) for c in ["WAERS","ZTERM","INCO1","MINBW"]
              if c in lfm1.columns]
        )
    )
    print(f"LFM1 clean rows: {lfm1_clean.count():,}")

if lfm2:
    lfm2_clean = (lfm2
        .filter(F.col("MANDT") == "010")
        .dropDuplicates(["LIFNR","EKORG","WERKS"])
        .select(
            F.col("LIFNR"),
            F.col("EKORG"),
            *[F.col(c) for c in ["WERKS","EKGRP"]
              if c in lfm2.columns]
        )
    )
    print(f"LFM2 clean rows: {lfm2_clean.count():,}")
```

```python
# ============================================================
# STEP 6 — Join LFA1 + LFM1 + LFM2
# ============================================================
silver_df = lfa1_clean

if lfm1:
    silver_df = silver_df.join(lfm1_clean, on="LIFNR", how="left")

if lfm2:
    silver_df = silver_df.join(lfm2_clean, on="LIFNR", how="left")

print(f"Silver joined rows: {silver_df.count():,}")
silver_df.show(5, truncate=False)
```

```python
# ============================================================
# STEP 7 — Write Silver to curated zone
# ============================================================
spark.conf.set("spark.databricks.delta.formatCheck.enabled", "false")

(silver_df
    .write
    .mode("overwrite")
    .format("parquet")
    .option("compression", "snappy")
    .save(f"{curated_path}/supplier_details"))

spark.conf.set("spark.databricks.delta.formatCheck.enabled", "true")
print("✅ Silver written to sap-ecc-curated/supplier_details")
```

```python
# ============================================================
# STEP 8 — Conformed: map to EAM.Supplier_Details schema
# ============================================================
conformed_df = (silver_df
    .select(
        F.col("LIFNR").alias("Supplier_Code"),
        F.col("NAME1").alias("Supplier_Description"),

        # Phone
        F.col("TELF1").alias("Supplier_Phone"),

        # Fax
        F.col("TELFX").alias("Supplier_Fax"),

        # Email — from SMTP_ADDR if available
        F.col("SMTP_ADDR").alias("Supplier_Email")
        if "SMTP_ADDR" in silver_df.columns
        else F.lit(None).cast("string").alias("Supplier_Email"),

        # Contact person
        F.col("ANSPK").alias("Supplier_Contact")
        if "ANSPK" in silver_df.columns
        else F.lit(None).cast("string").alias("Supplier_Contact"),

        # Address
        F.col("STRAS").alias("Supplier_Address"),
        F.col("ORT01").alias("Supplier_City"),
        F.col("LAND1").alias("Supplier_Country"),
        F.col("REGIO").alias("Supplier_Region"),

        # Status — map SPERR: space=Active, X=Blocked
        F.when(F.col("SPERR") == "X", "Blocked")
         .otherwise("Active")
         .alias("Supplier_Status"),

        # Account group
        F.col("KTOKK").alias("Supplier_Type_Account_Group"),

        # Tax
        F.col("STCD1").alias("Supplier_Tax_Number"),
        F.col("STCEG").alias("Supplier_VAT_Number"),

        # Purchasing org from LFM1
        F.col("EKORG").alias("Supplier_Purchase_Org")
        if "EKORG" in silver_df.columns
        else F.lit(None).cast("string").alias("Supplier_Purchase_Org"),

        # Currency from LFM1
        F.col("WAERS").alias("Supplier_Currency")
        if "WAERS" in silver_df.columns
        else F.lit(None).cast("string").alias("Supplier_Currency"),

        # Payment terms from LFM1
        F.col("ZTERM").alias("Supplier_Payment_Terms")
        if "ZTERM" in silver_df.columns
        else F.lit(None).cast("string").alias("Supplier_Payment_Terms"),
    )
    .filter(F.col("Supplier_Code").isNotNull())
)

print(f"Conformed rows: {conformed_df.count():,}")
conformed_df.show(10, truncate=False)
```

```python
# ============================================================
# STEP 9 — Write conformed as Parquet
# ============================================================
spark.conf.set("spark.databricks.delta.formatCheck.enabled", "false")

(conformed_df
    .write
    .mode("overwrite")
    .format("parquet")
    .option("compression", "snappy")
    .save(f"{conformed_path}/supplier_details"))

spark.conf.set("spark.databricks.delta.formatCheck.enabled", "true")
print("✅ Conformed written to sap-ecc-conformed/eam/supplier_details")
```

```python
# ============================================================
# STEP 10 — Data quality report
# ============================================================
total        = conformed_df.count()
null_code    = conformed_df.filter(F.col("Supplier_Code").isNull()).count()
null_name    = conformed_df.filter(F.col("Supplier_Description").isNull()).count()
null_email   = conformed_df.filter(F.col("Supplier_Email").isNull()).count()
null_country = conformed_df.filter(F.col("Supplier_Country").isNull()).count()
blocked      = conformed_df.filter(F.col("Supplier_Status") == "Blocked").count()
active       = conformed_df.filter(F.col("Supplier_Status") == "Active").count()

print(f"""
{'='*55}
EAM.Supplier_Details — Quality Report
{'='*55}
Total rows              : {total:,}
Null Supplier_Code      : {null_code:,}
Null Supplier_Name      : {null_name:,}
Null Supplier_Email     : {null_email:,}
Null Supplier_Country   : {null_country:,}
Active suppliers        : {active:,}
Blocked suppliers       : {blocked:,}
{'='*55}
""")
```

Run Step 1 first — it will tell you immediately which of LFA1, LFM1, LFM2 are available in your raw zone before we proceed.