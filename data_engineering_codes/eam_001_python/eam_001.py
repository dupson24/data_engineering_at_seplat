```python
# ============================================================
# EAM — Multi-Table Bronze → Silver → Conformed
# Full descriptive column names
# ============================================================

raw_base       = "/mnt/sap-ecc-datasphere/sap-ecc-raw"
tx_path        = f"{raw_base}/transaction-data"
master_path    = f"{raw_base}/master-data"
ref_path       = f"{raw_base}/reference-and-config"
co_path        = f"{raw_base}/co-budget"
eam_path       = f"{raw_base}/eam_ecc_raw_tables"
eam_path2      = f"{raw_base}/eam-ecc-raw-tables"
curated_path   = "/mnt/sap-ecc-datasphere/sap-ecc-curated/eam"
conformed_path = "/mnt/sap-ecc-datasphere/sap-ecc-conformed/eam"

MANDT = "010"
```

```python
# ============================================================
# UTILITY — Read initial + delta
# ============================================================
from pyspark.sql import functions as F

def read_table(folder_path, table_name):
    initial = (spark.read
        .option("recursiveFileLookup", "true")
        .option("mergeSchema", "true")
        .parquet(f"{folder_path}/{table_name}/initial"))
    print(f"{table_name} initial: {initial.count():,} rows")
    try:
        delta_files = [f for f in dbutils.fs.ls(f"{folder_path}/{table_name}/delta")
                       if f.name.endswith(".parquet")]
        if delta_files:
            delta = (spark.read
                .option("recursiveFileLookup", "true")
                .option("mergeSchema", "true")
                .parquet(f"{folder_path}/{table_name}/delta"))
            print(f"{table_name} delta  : {delta.count():,} rows")
            return initial.unionByName(delta)
        else:
            print(f"{table_name} delta  : no files yet")
    except:
        print(f"{table_name} delta  : not available")
    return initial

def safe_read(folder_path, table_name):
    """Read table, return None if not found."""
    try:
        df = read_table(folder_path, table_name)
        return df
    except Exception as e:
        print(f"⚠️ {table_name} not available at {folder_path}: {e}")
        return None

def write_conformed(df, target_name):
    spark.conf.set("spark.databricks.delta.formatCheck.enabled", "false")
    (df.write.mode("overwrite").format("parquet")
       .option("compression","snappy")
       .save(f"{conformed_path}/{target_name}"))
    spark.conf.set("spark.databricks.delta.formatCheck.enabled", "true")
    print(f"✅ {target_name}: {df.count():,} rows written")
```

```python
# ============================================================
# STEP 1 — DateDimension
# SCALTT_MONTH + SCALTT_TYP + SCALT_CONV + SCALT_MONTH +
# SCALT_TYPE + SCAL_TT_DATE + SCAL_TT_MONTH +
# SCAL_TT_WEEK + SCAL_TT_YEAR
# folder: eam_ecc_raw_tables
# ============================================================
scal_tables = [
    "SCALTT_MONTH","SCALTT_TYP","SCALT_CONV","SCALT_MONTH",
    "SCALT_TYPE","SCAL_TT_DATE","SCAL_TT_MONTH","SCAL_TT_WEEK","SCAL_TT_YEAR"
]

scal_dfs = {}
for t in scal_tables:
    df = safe_read(eam_path, t)
    if df:
        scal_dfs[t] = df
        print(f"{t} cols: {df.columns}")

# SCAL_TT_DATE is the primary date dimension driver
if "SCAL_TT_DATE" in scal_dfs:
    date_base = (scal_dfs["SCAL_TT_DATE"]
        .filter(F.col("MANDT") == MANDT)
        if "MANDT" in scal_dfs["SCAL_TT_DATE"].columns
        else scal_dfs["SCAL_TT_DATE"])

    date_base.show(5, truncate=False)
    print("SCAL_TT_DATE columns:", scal_dfs["SCAL_TT_DATE"].columns)
else:
    print("⚠️ SCAL_TT_DATE not found — check folder contents")
    for t, df in scal_dfs.items():
        print(f"\n{t} sample:")
        df.show(3, truncate=False)
```

```python
# Build DateDimension conformed — generated from SCAL_TT_DATE
# Inspect columns first then map
if "SCAL_TT_DATE" in scal_dfs:
    scal_date = scal_dfs["SCAL_TT_DATE"]
    print("Columns:", scal_date.columns)
    scal_date.show(5, truncate=False)
```

```python
# After inspecting columns — build DateDimension
# Column names will vary — use safe col_if_exists pattern
def c(df, col_name, alias, dtype="string", date_fmt="yyyyMMdd"):
    if col_name in df.columns:
        if dtype == "date":
            return F.to_date(F.col(col_name), date_fmt).alias(alias)
        elif dtype == "int":
            return F.col(col_name).cast("int").alias(alias)
        else:
            return F.col(col_name).alias(alias)
    return F.lit(None).cast(dtype if dtype not in ("date",) else "date").alias(alias)

if "SCAL_TT_DATE" in scal_dfs:
    scal_date = scal_dfs["SCAL_TT_DATE"]

    date_dimension_conformed = (scal_date
        .dropDuplicates()
        .select(
            c(scal_date, "DATUM",   "date",           "date"),
            c(scal_date, "WOCHTA",  "day_of_week",    "int"),
            c(scal_date, "MONBEG",  "month",          "int"),
            c(scal_date, "JAHPER",  "year",           "int"),
            c(scal_date, "PERIV",   "fiscal_period",  "string"),
            c(scal_date, "WOCHA",   "week_of_year",   "int"),
            c(scal_date, "KWEEK",   "week_of_month",  "int"),
            c(scal_date, "QUART",   "quarter",        "int"),
        )
    )

    write_conformed(date_dimension_conformed, "date_dimension")
```

```python
# ============================================================
# STEP 2 — Invoice_Voucher_Details
# BKPF + BSIK + RBKP — folder: transaction-data
# ============================================================
bkpf = safe_read(tx_path, "BKPF")
bsik = safe_read(tx_path, "BSIK")
rbkp = safe_read(tx_path, "RBKP")

if bkpf:
    print("\nBKPF columns:", bkpf.columns)
if bsik:
    print("BSIK columns:", bsik.columns)
if rbkp:
    print("RBKP columns:", rbkp.columns)
```

```python
if bkpf:
    bkpf_clean = (bkpf
        .filter(F.col("MANDT") == MANDT)
        .dropDuplicates(["BELNR","BUKRS","GJAHR"])
        .select(
            F.col("BELNR").alias("invoice_voucher_code"),
            F.col("BUKRS").alias("company_code"),
            F.col("GJAHR").alias("fiscal_year"),
            F.col("BLART").alias("document_type"),
            F.to_date(F.col("BLDAT"), "yyyyMMdd").alias("document_date"),
            F.to_date(F.col("BUDAT"), "yyyyMMdd").alias("posting_date"),
            F.col("WAERS").alias("currency"),
            F.col("BSTAT").alias("document_status")
            if "BSTAT" in bkpf.columns
            else F.lit(None).cast("string").alias("document_status"),
            F.col("XBLNR").alias("reference_number")
            if "XBLNR" in bkpf.columns
            else F.lit(None).cast("string").alias("reference_number"),
            F.col("BKTXT").alias("document_header_text")
            if "BKTXT" in bkpf.columns
            else F.lit(None).cast("string").alias("document_header_text"),
            F.col("USNAM").alias("created_by")
            if "USNAM" in bkpf.columns
            else F.lit(None).cast("string").alias("created_by"),
        )
    )

    # Join BSIK — open AP items
    if bsik:
        bsik_clean = (bsik
            .filter(F.col("MANDT") == MANDT)
            .dropDuplicates(["BELNR","BUKRS","GJAHR"])
            .select(
                F.col("BELNR"),
                F.col("BUKRS"),
                F.col("GJAHR"),
                F.col("LIFNR").alias("supplier_code")
                if "LIFNR" in bsik.columns
                else F.lit(None).cast("string").alias("supplier_code"),
                F.to_date(F.col("ZFBDT"), "yyyyMMdd").alias("payment_due_date")
                if "ZFBDT" in bsik.columns
                else F.lit(None).cast("date").alias("payment_due_date"),
                F.col("WRBTR").cast("decimal(18,2)").alias("total_amount")
                if "WRBTR" in bsik.columns
                else F.lit(None).cast("decimal(18,2)").alias("total_amount"),
                F.col("ZLSCH").alias("payment_method")
                if "ZLSCH" in bsik.columns
                else F.lit(None).cast("string").alias("payment_method"),
                F.to_date(F.col("AUGDT"), "yyyyMMdd").alias("cleared_date")
                if "AUGDT" in bsik.columns
                else F.lit(None).cast("date").alias("cleared_date"),
            )
        )
        invoice_silver = bkpf_clean.join(
            bsik_clean,
            on=["BELNR","BUKRS","GJAHR"],
            how="left"
        )
    else:
        invoice_silver = bkpf_clean

    # Join RBKP — LIV invoice header
    if rbkp:
        rbkp_clean = (rbkp
            .filter(F.col("MANDT") == MANDT)
            .dropDuplicates(["BELNR","GJAHR"])
            .select(
                F.col("BELNR"),
                F.col("GJAHR"),
                F.col("LIFNR").alias("liv_supplier_code")
                if "LIFNR" in rbkp.columns
                else F.lit(None).cast("string").alias("liv_supplier_code"),
                F.col("RMWWR").cast("decimal(18,2)").alias("gross_invoice_amount")
                if "RMWWR" in rbkp.columns
                else F.lit(None).cast("decimal(18,2)").alias("gross_invoice_amount"),
                F.col("RBSTAT").alias("invoice_status")
                if "RBSTAT" in rbkp.columns
                else F.lit(None).cast("string").alias("invoice_status"),
                F.col("XBLNR").alias("external_invoice_number")
                if "XBLNR" in rbkp.columns
                else F.lit(None).cast("string").alias("external_invoice_number"),
            )
        )
        invoice_silver = invoice_silver.join(
            rbkp_clean,
            on=["BELNR","GJAHR"],
            how="left"
        )

    invoice_conformed = invoice_silver.filter(
        F.col("invoice_voucher_code").isNotNull()
    )

    write_conformed(invoice_conformed, "invoice_voucher_details")
```

```python
# ============================================================
# STEP 3 — Invoice_Voucher_Line_Details
# BSEG + RSEG — folder: transaction-data
# ============================================================
bseg = safe_read(tx_path, "BSEG")
rseg = safe_read(tx_path, "RSEG")

if bseg:
    print("\nBSEG columns:", bseg.columns)
if rseg:
    print("RSEG columns:", rseg.columns)
```

```python
if bseg:
    bseg_clean = (bseg
        .filter(F.col("MANDT") == MANDT)
        .dropDuplicates(["BELNR","BUKRS","GJAHR","BUZEI"])
        .select(
            F.col("BELNR").alias("invoice_voucher_code"),
            F.col("BUKRS").alias("company_code"),
            F.col("GJAHR").alias("fiscal_year"),
            F.col("BUZEI").alias("line_item_number"),
            F.col("HKONT").alias("gl_account")
            if "HKONT" in bseg.columns
            else F.lit(None).cast("string").alias("gl_account"),
            F.col("LIFNR").alias("supplier_code")
            if "LIFNR" in bseg.columns
            else F.lit(None).cast("string").alias("supplier_code"),
            F.col("WRBTR").cast("decimal(18,2)").alias("transaction_amount")
            if "WRBTR" in bseg.columns
            else F.lit(None).cast("decimal(18,2)").alias("transaction_amount"),
            F.col("DMBTR").cast("decimal(18,2)").alias("local_currency_amount")
            if "DMBTR" in bseg.columns
            else F.lit(None).cast("decimal(18,2)").alias("local_currency_amount"),
            F.col("WAERS").alias("currency")
            if "WAERS" in bseg.columns
            else F.lit(None).cast("string").alias("currency"),
            F.col("SHKZG").alias("debit_credit_indicator")
            if "SHKZG" in bseg.columns
            else F.lit(None).cast("string").alias("debit_credit_indicator"),
            F.col("SGTXT").alias("line_item_text")
            if "SGTXT" in bseg.columns
            else F.lit(None).cast("string").alias("line_item_text"),
            F.col("KOSTL").alias("cost_centre")
            if "KOSTL" in bseg.columns
            else F.lit(None).cast("string").alias("cost_centre"),
            F.col("AUFNR").alias("order_number")
            if "AUFNR" in bseg.columns
            else F.lit(None).cast("string").alias("order_number"),
            F.col("MWSTS").cast("decimal(18,2)").alias("tax_amount")
            if "MWSTS" in bseg.columns
            else F.lit(None).cast("decimal(18,2)").alias("tax_amount"),
        )
    )

    if rseg:
        rseg_clean = (rseg
            .filter(F.col("MANDT") == MANDT)
            .dropDuplicates(["BELNR","GJAHR","BUZEI"])
            .select(
                F.col("BELNR"),
                F.col("GJAHR"),
                F.col("BUZEI"),
                F.col("EBELN").alias("purchase_order_number")
                if "EBELN" in rseg.columns
                else F.lit(None).cast("string").alias("purchase_order_number"),
                F.col("EBELP").alias("purchase_order_item")
                if "EBELP" in rseg.columns
                else F.lit(None).cast("string").alias("purchase_order_item"),
                F.col("MENGE").cast("decimal(18,3)").alias("invoice_quantity")
                if "MENGE" in rseg.columns
                else F.lit(None).cast("decimal(18,3)").alias("invoice_quantity"),
                F.col("WRBTR").cast("decimal(18,2)").alias("invoice_amount")
                if "WRBTR" in rseg.columns
                else F.lit(None).cast("decimal(18,2)").alias("invoice_amount"),
                F.col("MATNR").alias("material_code")
                if "MATNR" in rseg.columns
                else F.lit(None).cast("string").alias("material_code"),
            )
        )
        invoice_line_silver = bseg_clean.join(
            rseg_clean,
            on=["BELNR","GJAHR","BUZEI"],
            how="left"
        )
    else:
        invoice_line_silver = bseg_clean

    invoice_line_conformed = invoice_line_silver.filter(
        F.col("invoice_voucher_code").isNotNull()
    )

    write_conformed(invoice_line_conformed, "invoice_voucher_line_details")
```

```python
# ============================================================
# STEP 4 — Organisation_Details
# T001 + TBUKRS — folder: eam_ecc_raw_tables
# TKA01         — folder: co-budget
# ============================================================
t001  = safe_read(eam_path, "T001")
tbukrs= safe_read(eam_path, "TBUKRS")
tka01 = safe_read(co_path,  "TKA01")

if t001:   print("\nT001   columns:", t001.columns)
if tbukrs: print("TBUKRS columns:", tbukrs.columns)
if tka01:  print("TKA01  columns:", tka01.columns)
```

```python
if t001:
    t001_clean = (t001
        .filter(F.col("MANDT") == MANDT)
        if "MANDT" in t001.columns
        else t001
    )
    t001_clean = (t001_clean
        .dropDuplicates(["BUKRS"])
        .select(
            F.col("BUKRS").alias("organisation_code"),
            F.col("BUTXT").alias("organisation_description")
            if "BUTXT" in t001.columns
            else F.lit(None).cast("string").alias("organisation_description"),
            F.col("WAERS").alias("organisation_currency")
            if "WAERS" in t001.columns
            else F.lit(None).cast("string").alias("organisation_currency"),
            F.col("LAND1").alias("country")
            if "LAND1" in t001.columns
            else F.lit(None).cast("string").alias("country"),
            F.col("SPRAS").alias("language")
            if "SPRAS" in t001.columns
            else F.lit(None).cast("string").alias("language"),
            F.col("ADRNR").alias("address_number")
            if "ADRNR" in t001.columns
            else F.lit(None).cast("string").alias("address_number"),
            F.col("PERIV").alias("fiscal_year_variant")
            if "PERIV" in t001.columns
            else F.lit(None).cast("string").alias("fiscal_year_variant"),
        )
    )

    org_silver = t001_clean

    if tka01:
        tka01_clean = (tka01
            .filter(F.col("MANDT") == MANDT)
            if "MANDT" in tka01.columns
            else tka01
        )
        tka01_clean = (tka01_clean
            .dropDuplicates(["KOKRS"])
            .select(
                F.col("KOKRS").alias("controlling_area"),
                F.col("BEZEI").alias("controlling_area_description")
                if "BEZEI" in tka01.columns
                else F.lit(None).cast("string").alias("controlling_area_description"),
                F.col("WAERS").alias("controlling_area_currency")
                if "WAERS" in tka01.columns
                else F.lit(None).cast("string").alias("controlling_area_currency"),
                F.col("BUKRS").alias("BUKRS")
                if "BUKRS" in tka01.columns
                else F.lit(None).cast("string").alias("BUKRS"),
            )
        )
        org_silver = org_silver.join(
            tka01_clean,
            org_silver["organisation_code"] == tka01_clean["BUKRS"],
            how="left"
        ).drop("BUKRS")

    org_conformed = org_silver.filter(F.col("organisation_code").isNotNull())
    write_conformed(org_conformed, "organisation_details")
```

```python
# ============================================================
# STEP 5 — Parts_Details
# MARA + MAKT + MARC — folder: master-data
# MARM             — folder: eam_ecc_raw_tables
# ============================================================
mara = safe_read(master_path, "MARA")
makt = safe_read(master_path, "MAKT")
marc = safe_read(master_path, "MARC")
marm = safe_read(eam_path,    "MARM")

if mara: print("\nMARA columns:", mara.columns)
if makt: print("MAKT columns:", makt.columns)
if marc: print("MARC columns:", marc.columns)
if marm: print("MARM columns:", marm.columns)
```

```python
if mara:
    mara_clean = (mara
        .filter(F.col("MANDT") == MANDT)
        .dropDuplicates(["MATNR"])
        .select(
            F.col("MATNR").alias("material_code"),
            F.col("MATKL").alias("material_group")
            if "MATKL" in mara.columns
            else F.lit(None).cast("string").alias("material_group"),
            F.col("MTART").alias("material_type")
            if "MTART" in mara.columns
            else F.lit(None).cast("string").alias("material_type"),
            F.col("MEINS").alias("base_unit_of_measure")
            if "MEINS" in mara.columns
            else F.lit(None).cast("string").alias("base_unit_of_measure"),
            F.col("NORMT").alias("industry_standard_description")
            if "NORMT" in mara.columns
            else F.lit(None).cast("string").alias("industry_standard_description"),
            F.col("BRGEW").cast("decimal(18,3)").alias("gross_weight")
            if "BRGEW" in mara.columns
            else F.lit(None).cast("decimal(18,3)").alias("gross_weight"),
            F.col("NTGEW").cast("decimal(18,3)").alias("net_weight")
            if "NTGEW" in mara.columns
            else F.lit(None).cast("decimal(18,3)").alias("net_weight"),
            F.col("GEWEI").alias("weight_unit")
            if "GEWEI" in mara.columns
            else F.lit(None).cast("string").alias("weight_unit"),
            F.to_date(F.col("ERSDA"), "yyyyMMdd").alias("created_date")
            if "ERSDA" in mara.columns
            else F.lit(None).cast("date").alias("created_date"),
        )
    )

    parts_silver = mara_clean

    # Join MAKT — descriptions
    if makt:
        makt_clean = (makt
            .filter(F.col("MANDT") == MANDT)
            .filter(F.col("SPRAS") == "E")
            .dropDuplicates(["MATNR"])
            .select(
                F.col("MATNR"),
                F.col("MAKTX").alias("material_description"),
            )
        )
        parts_silver = parts_silver.join(makt_clean, on="MATNR", how="left")

    # Join MARC — plant level
    if marc:
        marc_clean = (marc
            .filter(F.col("MANDT") == MANDT)
            .dropDuplicates(["MATNR","WERKS"])
            .select(
                F.col("MATNR"),
                F.col("WERKS").alias("plant"),
                F.col("EKGRP").alias("purchasing_group")
                if "EKGRP" in marc.columns
                else F.lit(None).cast("string").alias("purchasing_group"),
                F.col("MTVFP").alias("checking_rule")
                if "MTVFP" in marc.columns
                else F.lit(None).cast("string").alias("checking_rule"),
                F.col("MINBE").cast("decimal(18,3)").alias("reorder_point")
                if "MINBE" in marc.columns
                else F.lit(None).cast("decimal(18,3)").alias("reorder_point"),
                F.col("EISBE").cast("decimal(18,3)").alias("safety_stock")
                if "EISBE" in marc.columns
                else F.lit(None).cast("decimal(18,3)").alias("safety_stock"),
            )
        )
        parts_silver = parts_silver.join(marc_clean, on="MATNR", how="left")

    # Join MARM — unit of measure conversions
    if marm:
        marm_clean = (marm
            .filter(F.col("MANDT") == MANDT)
            .dropDuplicates(["MATNR","MEINH"])
            .select(
                F.col("MATNR"),
                F.col("MEINH").alias("alternative_uom")
                if "MEINH" in marm.columns
                else F.lit(None).cast("string").alias("alternative_uom"),
                F.col("UMREZ").cast("decimal(18,3)").alias("conversion_numerator")
                if "UMREZ" in marm.columns
                else F.lit(None).cast("decimal(18,3)").alias("conversion_numerator"),
                F.col("UMREN").cast("decimal(18,3)").alias("conversion_denominator")
                if "UMREN" in marm.columns
                else F.lit(None).cast("decimal(18,3)").alias("conversion_denominator"),
            )
        )
        parts_silver = parts_silver.join(marm_clean, on="MATNR", how="left")

    parts_conformed = parts_silver.filter(F.col("material_code").isNotNull())
    write_conformed(parts_conformed, "parts_details")
```

```python
# ============================================================
# STEP 6 — Parts_Stock_Details
# MARD + MCHB — folder: eam-ecc-raw-tables
# MSEG        — folder: transaction-data
# ============================================================
mard = safe_read(eam_path2, "MARD")
mchb = safe_read(eam_path2, "MCHB")
mseg = safe_read(tx_path,   "MSEG")

if mard: print("\nMARD columns:", mard.columns)
if mchb: print("MCHB columns:", mchb.columns)
if mseg: print("MSEG columns:", mseg.columns)
```

```python
if mard:
    mard_clean = (mard
        .filter(F.col("MANDT") == MANDT)
        .dropDuplicates(["MATNR","WERKS","LGORT"])
        .select(
            F.col("MATNR").alias("material_code"),
            F.col("WERKS").alias("plant"),
            F.col("LGORT").alias("storage_location"),
            F.col("LABST").cast("decimal(18,3)").alias("unrestricted_stock_quantity")
            if "LABST" in mard.columns
            else F.lit(None).cast("decimal(18,3)").alias("unrestricted_stock_quantity"),
            F.col("INSME").cast("decimal(18,3)").alias("quality_inspection_stock")
            if "INSME" in mard.columns
            else F.lit(None).cast("decimal(18,3)").alias("quality_inspection_stock"),
            F.col("EINME").cast("decimal(18,3)").alias("restricted_use_stock")
            if "EINME" in mard.columns
            else F.lit(None).cast("decimal(18,3)").alias("restricted_use_stock"),
            F.col("SPEME").cast("decimal(18,3)").alias("blocked_stock")
            if "SPEME" in mard.columns
            else F.lit(None).cast("decimal(18,3)").alias("blocked_stock"),
        )
    )

    stock_silver = mard_clean

    if mchb:
        mchb_clean = (mchb
            .filter(F.col("MANDT") == MANDT)
            .dropDuplicates(["MATNR","WERKS","LGORT","CHARG"])
            .select(
                F.col("MATNR").alias("material_code"),
                F.col("WERKS").alias("plant"),
                F.col("LGORT").alias("storage_location"),
                F.col("CHARG").alias("batch_number")
                if "CHARG" in mchb.columns
                else F.lit(None).cast("string").alias("batch_number"),
                F.col("CLABS").cast("decimal(18,3)").alias("batch_unrestricted_stock")
                if "CLABS" in mchb.columns
                else F.lit(None).cast("decimal(18,3)").alias("batch_unrestricted_stock"),
            )
        )
        stock_silver = stock_silver.join(
            mchb_clean,
            on=["material_code","plant","storage_location"],
            how="left"
        )

    if mseg:
        mseg_clean = (mseg
            .filter(F.col("MANDT") == MANDT)
            .dropDuplicates(["MBLNR","MJAHR","ZEILE"])
            .select(
                F.col("MATNR").alias("material_code"),
                F.col("WERKS").alias("plant"),
                F.col("LGORT").alias("storage_location"),
                F.col("MBLNR").alias("material_document_number"),
                F.col("MJAHR").alias("material_document_year"),
                F.col("ZEILE").alias("document_item"),
                F.col("BWART").alias("movement_type")
                if "BWART" in mseg.columns
                else F.lit(None).cast("string").alias("movement_type"),
                F.col("MENGE").cast("decimal(18,3)").alias("movement_quantity")
                if "MENGE" in mseg.columns
                else F.lit(None).cast("decimal(18,3)").alias("movement_quantity"),
                F.col("MEINS").alias("unit_of_measure")
                if "MEINS" in mseg.columns
                else F.lit(None).cast("string").alias("unit_of_measure"),
                F.to_date(F.col("BUDAT"), "yyyyMMdd").alias("posting_date")
                if "BUDAT" in mseg.columns
                else F.lit(None).cast("date").alias("posting_date"),
            )
        )
        stock_silver = stock_silver.join(
            mseg_clean,
            on=["material_code","plant","storage_location"],
            how="left"
        )

    stock_conformed = stock_silver.filter(F.col("material_code").isNotNull())
    write_conformed(stock_conformed, "parts_stock_details")
```

```python
# ============================================================
# STEP 7 — Parts_Store_Details
# MARC + MARA — folder: master-data
# MBEW        — folder: eam-ecc-raw-tables
# ============================================================
mbew = safe_read(eam_path2, "MBEW")
if mbew: print("\nMBEW columns:", mbew.columns)

if mara and marc:
    store_silver = (marc
        .filter(F.col("MANDT") == MANDT)
        .dropDuplicates(["MATNR","WERKS"])
        .select(
            F.col("MATNR").alias("material_code"),
            F.col("WERKS").alias("plant"),
            F.col("LGPBE").alias("storage_bin")
            if "LGPBE" in marc.columns
            else F.lit(None).cast("string").alias("storage_bin"),
            F.col("MINBE").cast("decimal(18,3)").alias("minimum_stock_level")
            if "MINBE" in marc.columns
            else F.lit(None).cast("decimal(18,3)").alias("minimum_stock_level"),
            F.col("MABST").cast("decimal(18,3)").alias("maximum_stock_level")
            if "MABST" in marc.columns
            else F.lit(None).cast("decimal(18,3)").alias("maximum_stock_level"),
            F.col("EISBE").cast("decimal(18,3)").alias("safety_stock_level")
            if "EISBE" in marc.columns
            else F.lit(None).cast("decimal(18,3)").alias("safety_stock_level"),
            F.col("MTVFP").alias("reorder_point_method")
            if "MTVFP" in marc.columns
            else F.lit(None).cast("string").alias("reorder_point_method"),
            F.col("EKGRP").alias("purchasing_group")
            if "EKGRP" in marc.columns
            else F.lit(None).cast("string").alias("purchasing_group"),
        )
    )

    # Join MARA for description
    mara_desc = (mara
        .filter(F.col("MANDT") == MANDT)
        .dropDuplicates(["MATNR"])
        .select(
            F.col("MATNR"),
            F.col("MEINS").alias("base_unit_of_measure"),
            F.col("MATKL").alias("material_group"),
        )
    )
    store_silver = store_silver.join(mara_desc, on="MATNR", how="left")

    # Join MBEW — valuation
    if mbew:
        mbew_clean = (mbew
            .filter(F.col("MANDT") == MANDT)
            .dropDuplicates(["MATNR","BWKEY"])
            .select(
                F.col("MATNR").alias("material_code"),
                F.col("BWKEY").alias("valuation_area")
                if "BWKEY" in mbew.columns
                else F.lit(None).cast("string").alias("valuation_area"),
                F.col("VERPR").cast("decimal(18,4)").alias("moving_average_price")
                if "VERPR" in mbew.columns
                else F.lit(None).cast("decimal(18,4)").alias("moving_average_price"),
                F.col("STPRS").cast("decimal(18,4)").alias("standard_price")
                if "STPRS" in mbew.columns
                else F.lit(None).cast("decimal(18,4)").alias("standard_price"),
                F.col("PEINH").cast("int").alias("price_unit")
                if "PEINH" in mbew.columns
                else F.lit(None).cast("int").alias("price_unit"),
                F.col("BKLAS").alias("valuation_class")
                if "BKLAS" in mbew.columns
                else F.lit(None).cast("string").alias("valuation_class"),
                F.col("LBKUM").cast("decimal(18,3)").alias("total_valuated_stock")
                if "LBKUM" in mbew.columns
                else F.lit(None).cast("decimal(18,3)").alias("total_valuated_stock"),
                F.col("SALK3").cast("decimal(18,2)").alias("total_stock_value")
                if "SALK3" in mbew.columns
                else F.lit(None).cast("decimal(18,2)").alias("total_stock_value"),
            )
        )
        store_silver = store_silver.join(mbew_clean, on="material_code", how="left")

    store_conformed = store_silver.filter(F.col("material_code").isNotNull())
    write_conformed(store_conformed, "parts_store_details")
```

```python
# ============================================================
# STEP 8 — Purchase_Order_Details
# EKKO — folder: transaction-data
# ============================================================
ekko = safe_read(tx_path, "EKKO")
if ekko: print("\nEKKO columns:", ekko.columns)

if ekko:
    po_details_conformed = (ekko
        .filter(F.col("MANDT") == MANDT)
        .dropDuplicates(["EBELN"])
        .select(
            F.col("EBELN").alias("purchase_order_code"),
            F.col("LIFNR").alias("supplier_code"),
            F.col("EKORG").alias("purchasing_organisation"),
            F.col("EKGRP").alias("purchasing_group"),
            F.col("BSART").alias("purchase_order_type"),
            F.col("WAERS").alias("currency"),
            F.to_date(F.col("BEDAT"), "yyyyMMdd").alias("purchase_order_date"),
            F.when(F.col("LOEKZ") == "L", "Closed")
             .otherwise("Active").alias("purchase_order_status"),
            F.col("ERNAM").alias("created_by")
            if "ERNAM" in ekko.columns
            else F.lit(None).cast("string").alias("created_by"),
            F.col("WERKS").alias("plant")
            if "WERKS" in ekko.columns
            else F.lit(None).cast("string").alias("plant"),
            F.to_date(F.col("FRGDT"), "yyyyMMdd").alias("approval_date")
            if "FRGDT" in ekko.columns
            else F.lit(None).cast("date").alias("approval_date"),
            F.to_date(F.col("KDATB"), "yyyyMMdd").alias("validity_start_date")
            if "KDATB" in ekko.columns
            else F.lit(None).cast("date").alias("validity_start_date"),
            F.to_date(F.col("KDATE"), "yyyyMMdd").alias("validity_end_date")
            if "KDATE" in ekko.columns
            else F.lit(None).cast("date").alias("validity_end_date"),
        )
        .filter(F.col("purchase_order_code").isNotNull())
    )
    write_conformed(po_details_conformed, "purchase_order_details")
```

```python
# ============================================================
# STEP 9 — Purchase_Order_Parts_Details
# EKPO — folder: transaction-data
# ============================================================
if ekpo:
    delivery_date_col = next(
        (c for c in ["EINDT","EILDT","AGDAT","PRDAT"] if c in ekpo.columns), None
    )
    print(f"Delivery date column: {delivery_date_col}")

    po_parts_conformed = (ekpo
        .filter(F.col("MANDT") == MANDT)
        .filter(F.col("PSTYP").isin(["0","1","2","3","5","9"])
                if "PSTYP" in ekpo.columns else F.lit(True))
        .dropDuplicates(["EBELN","EBELP"])
        .select(
            F.col("EBELN").alias("purchase_order_code"),
            F.col("EBELP").alias("purchase_order_item"),
            F.col("MATNR").alias("material_code"),
            F.col("TXZ01").alias("item_description"),
            F.col("MENGE").cast("decimal(18,3)").alias("order_quantity"),
            F.col("MEINS").alias("unit_of_measure"),
            F.col("NETPR").cast("decimal(18,2)").alias("net_price"),
            F.col("NETWR").cast("decimal(18,2)").alias("net_value")
            if "NETWR" in ekpo.columns
            else F.lit(None).cast("decimal(18,2)").alias("net_value"),
            F.col("MATKL").alias("material_group"),
            F.col("WERKS").alias("plant"),
            F.to_date(F.col(delivery_date_col), "yyyyMMdd").alias("delivery_date")
            if delivery_date_col
            else F.lit(None).cast("date").alias("delivery_date"),
            F.when(F.col("LOEKZ") == "L", "Deleted")
             .otherwise("Active").alias("item_status"),
            F.when(F.col("ELIKZ") == "X", "Complete")
             .otherwise("Open").alias("delivery_completion_status")
            if "ELIKZ" in ekpo.columns
            else F.lit("Open").alias("delivery_completion_status"),
        )
        .filter(F.col("purchase_order_code").isNotNull())
    )
    write_conformed(po_parts_conformed, "purchase_order_parts_details")
```

```python
# ============================================================
# STEP 10 — Purchase_Order_Receipt_Details
# MKPF — folder: transaction-data
# ============================================================
mkpf = safe_read(tx_path, "MKPF")
if mkpf: print("\nMKPF columns:", mkpf.columns)

if mkpf:
    po_receipt_conformed = (mkpf
        .filter(F.col("MANDT") == MANDT)
        .dropDuplicates(["MBLNR","MJAHR"])
        .select(
            F.col("MBLNR").alias("goods_receipt_document_number"),
            F.col("MJAHR").alias("material_document_year"),
            F.to_date(F.col("BUDAT"), "yyyyMMdd").alias("posting_date"),
            F.to_date(F.col("BLDAT"), "yyyyMMdd").alias("document_date")
            if "BLDAT" in mkpf.columns
            else F.lit(None).cast("date").alias("document_date"),
            F.col("USNAM").alias("received_by")
            if "USNAM" in mkpf.columns
            else F.lit(None).cast("string").alias("received_by"),
            F.col("BKTXT").alias("document_header_text")
            if "BKTXT" in mkpf.columns
            else F.lit(None).cast("string").alias("document_header_text"),
            F.col("BLART").alias("document_type")
            if "BLART" in mkpf.columns
            else F.lit(None).cast("string").alias("document_type"),
            F.col("WERKS").alias("plant")
            if "WERKS" in mkpf.columns
            else F.lit(None).cast("string").alias("plant"),
        )
        .filter(F.col("goods_receipt_document_number").isNotNull())
    )
    write_conformed(po_receipt_conformed, "purchase_order_receipt_details")
```

```python
# ============================================================
# STEP 11 — Purchase_Order_Receipt_PackingSlip_Active_Lines
# MSEG — active lines only (SHKZG=S, XAUTO=' ')
# folder: transaction-data
# ============================================================
if mseg:
    po_active_lines_conformed = (mseg
        .filter(F.col("MANDT") == MANDT)
        .filter(
            (F.col("SHKZG") == "S") &
            (F.col("XAUTO") == " " if "XAUTO" in mseg.columns else F.lit(True))
        )
        .dropDuplicates(["MBLNR","MJAHR","ZEILE"])
        .select(
            F.col("MBLNR").alias("goods_receipt_document_number"),
            F.col("MJAHR").alias("material_document_year"),
            F.col("ZEILE").alias("document_line_item"),
            F.col("MATNR").alias("material_code"),
            F.col("WERKS").alias("plant"),
            F.col("LGORT").alias("storage_location")
            if "LGORT" in mseg.columns
            else F.lit(None).cast("string").alias("storage_location"),
            F.col("MENGE").cast("decimal(18,3)").alias("goods_receipt_quantity"),
            F.col("MEINS").alias("unit_of_measure"),
            F.col("EBELN").alias("purchase_order_number")
            if "EBELN" in mseg.columns
            else F.lit(None).cast("string").alias("purchase_order_number"),
            F.col("EBELP").alias("purchase_order_item")
            if "EBELP" in mseg.columns
            else F.lit(None).cast("string").alias("purchase_order_item"),
            F.col("BWART").alias("movement_type")
            if "BWART" in mseg.columns
            else F.lit(None).cast("string").alias("movement_type"),
            F.to_date(F.col("BUDAT"), "yyyyMMdd").alias("posting_date")
            if "BUDAT" in mseg.columns
            else F.lit(None).cast("date").alias("posting_date"),
            F.col("SHKZG").alias("debit_credit_indicator"),
        )
        .filter(F.col("goods_receipt_document_number").isNotNull())
    )
    write_conformed(po_active_lines_conformed,
                    "purchase_order_receipt_packingslip_active_lines_details")
```

```python
# ============================================================
# STEP 12 — Purchase_Order_Receipts_PackingSlip_Details
# MSEG + LIKP/LIPS — folder: eam-ecc-raw-tables
# ============================================================
likp = safe_read(eam_path2, "LIKP")
lips = safe_read(eam_path2, "LIPS")

if likp: print("\nLIKP columns:", likp.columns)
if lips: print("LIPS  columns:", lips.columns)

if mseg:
    packing_slip_silver = (mseg
        .filter(F.col("MANDT") == MANDT)
        .dropDuplicates(["MBLNR","MJAHR","ZEILE"])
        .select(
            F.col("MBLNR").alias("goods_receipt_document_number"),
            F.col("MJAHR").alias("material_document_year"),
            F.col("ZEILE").alias("document_line_item"),
            F.col("MATNR").alias("material_code"),
            F.col("WERKS").alias("plant"),
            F.col("MENGE").cast("decimal(18,3)").alias("delivered_quantity"),
            F.col("MEINS").alias("unit_of_measure"),
            F.col("EBELN").alias("purchase_order_number")
            if "EBELN" in mseg.columns
            else F.lit(None).cast("string").alias("purchase_order_number"),
            F.col("VBELN").alias("delivery_document_number")
            if "VBELN" in mseg.columns
            else F.lit(None).cast("string").alias("delivery_document_number"),
        )
    )

    if lips:
        lips_clean = (lips
            .filter(F.col("MANDT") == MANDT)
            .dropDuplicates(["VBELN","POSNR"])
            .select(
                F.col("VBELN").alias("delivery_document_number"),
                F.col("POSNR").alias("delivery_item"),
                F.col("MATNR").alias("material_code"),
                F.col("LFIMG").cast("decimal(18,3)").alias("delivery_quantity")
                if "LFIMG" in lips.columns
                else F.lit(None).cast("decimal(18,3)").alias("delivery_quantity"),
                F.col("LGORT").alias("storage_location")
                if "LGORT" in lips.columns
                else F.lit(None).cast("string").alias("storage_location"),
            )
        )
        packing_slip_silver = packing_slip_silver.join(
            lips_clean,
            on="delivery_document_number",
            how="left"
        )

    if likp:
        likp_clean = (likp
            .filter(F.col("MANDT") == MANDT)
            .dropDuplicates(["VBELN"])
            .select(
                F.col("VBELN").alias("delivery_document_number"),
                F.to_date(F.col("WADAT"), "yyyyMMdd").alias("planned_goods_issue_date")
                if "WADAT" in likp.columns
                else F.lit(None).cast("date").alias("planned_goods_issue_date"),
                F.col("KUNNR").alias("ship_to_customer")
                if "KUNNR" in likp.columns
                else F.lit(None).cast("string").alias("ship_to_customer"),
                F.col("LFART").alias("delivery_type")
                if "LFART" in likp.columns
                else F.lit(None).cast("string").alias("delivery_type"),
            )
        )
        packing_slip_silver = packing_slip_silver.join(
            likp_clean,
            on="delivery_document_number",
            how="left"
        )

    packing_slip_conformed = packing_slip_silver.filter(
        F.col("goods_receipt_document_number").isNotNull()
    )
    write_conformed(packing_slip_conformed,
                    "purchase_order_receipts_packingslip_details")
```

```python
# ============================================================
# STEP 13 — Purchase_Order_Service_Receipts_Details
# ESLH + ESLL — folder: eam-ecc-raw-tables
# ============================================================
eslh = safe_read(eam_path2, "ESLH")
esll = safe_read(eam_path2, "ESLL")

if eslh: print("\nESLH columns:", eslh.columns)
if esll: print("ESLL  columns:", esll.columns)

if eslh:
    eslh_clean = (eslh
        .filter(F.col("MANDT") == MANDT)
        .dropDuplicates(["LBLNI","LBLNR"])
        .select(
            F.col("LBLNR").alias("service_entry_sheet_number"),
            F.col("LBLNI").alias("service_entry_sheet_item"),
            F.col("EBELN").alias("purchase_order_number")
            if "EBELN" in eslh.columns
            else F.lit(None).cast("string").alias("purchase_order_number"),
            F.col("EBELP").alias("purchase_order_item")
            if "EBELP" in eslh.columns
            else F.lit(None).cast("string").alias("purchase_order_item"),
            F.col("ERNAM").alias("created_by")
            if "ERNAM" in eslh.columns
            else F.lit(None).cast("string").alias("created_by"),
            F.to_date(F.col("ERDAT"), "yyyyMMdd").alias("created_date")
            if "ERDAT" in eslh.columns
            else F.lit(None).cast("date").alias("created_date"),
            F.col("BSTAT").alias("service_entry_status")
            if "BSTAT" in eslh.columns
            else F.lit(None).cast("string").alias("service_entry_status"),
        )
    )

    if esll:
        esll_clean = (esll
            .filter(F.col("MANDT") == MANDT)
            .dropDuplicates(["LBLNI","LBLNR","PACKNO","INTROW"])
            .select(
                F.col("LBLNR").alias("service_entry_sheet_number"),
                F.col("LBLNI").alias("service_entry_sheet_item"),
                F.col("SRVPOS").alias("service_number")
                if "SRVPOS" in esll.columns
                else F.lit(None).cast("string").alias("service_number"),
                F.col("KTEXT1").alias("service_description")
                if "KTEXT1" in esll.columns
                else F.lit(None).cast("string").alias("service_description"),
                F.col("MENGE").cast("decimal(18,3)").alias("service_quantity")
                if "MENGE" in esll.columns
                else F.lit(None).cast("decimal(18,3)").alias("service_quantity"),
                F.col("MEINS").alias("unit_of_measure")
                if "MEINS" in esll.columns
                else F.lit(None).cast("string").alias("unit_of_measure"),
                F.col("TBTWR").cast("decimal(18,2)").alias("total_value")
                if "TBTWR" in esll.columns
                else F.lit(None).cast("decimal(18,2)").alias("total_value"),
                F.col("PREISZ").cast("decimal(18,4)").alias("price_per_unit")
                if "PREISZ" in esll.columns
                else F.lit(None).cast("decimal(18,4)").alias("price_per_unit"),
            )
        )
        service_receipt_silver = eslh_clean.join(
            esll_clean,
            on=["service_entry_sheet_number","service_entry_sheet_item"],
            how="left"
        )
    else:
        service_receipt_silver = eslh_clean

    service_receipt_conformed = service_receipt_silver.filter(
        F.col("service_entry_sheet_number").isNotNull()
    )
    write_conformed(service_receipt_conformed,
                    "purchase_order_service_receipts_details")
```

```python
# ============================================================
# STEP 14 — Purchase_Order_Services_Details
# EKPO — folder: transaction-data (service items only)
# EKPV — folder: eam-ecc-raw-tables
# ============================================================
ekpv = safe_read(eam_path2, "EKPV")
if ekpv: print("\nEKPV columns:", ekpv.columns)

if ekpo:
    # Filter service items only — PSTYP = D or item category service
    po_services_conformed = (ekpo
        .filter(F.col("MANDT") == MANDT)
        .filter(F.col("PSTYP") == "D"
                if "PSTYP" in ekpo.columns
                else F.lit(True))
        .dropDuplicates(["EBELN","EBELP"])
        .select(
            F.col("EBELN").alias("purchase_order_code"),
            F.col("EBELP").alias("purchase_order_item"),
            F.col("TXZ01").alias("service_description"),
            F.col("NETPR").cast("decimal(18,2)").alias("net_price"),
            F.col("NETWR").cast("decimal(18,2)").alias("net_value")
            if "NETWR" in ekpo.columns
            else F.lit(None).cast("decimal(18,2)").alias("net_value"),
            F.col("MENGE").cast("decimal(18,3)").alias("quantity"),
            F.col("MEINS").alias("unit_of_measure"),
            F.col("WERKS").alias("plant"),
            F.col("LOEKZ").alias("deletion_indicator")
            if "LOEKZ" in ekpo.columns
            else F.lit(None).cast("string").alias("deletion_indicator"),
        )
    )

    if ekpv:
        ekpv_clean = (ekpv
            .filter(F.col("MANDT") == MANDT)
            if "MANDT" in ekpv.columns
            else ekpv
        )
        ekpv_clean = (ekpv_clean
            .dropDuplicates(["EBELN","EBELP"])
            .select(
                F.col("EBELN").alias("purchase_order_code"),
                F.col("EBELP").alias("purchase_order_item"),
                *[F.col(c) for c in ekpv_clean.columns
                  if c not in ["EBELN","EBELP","MANDT",
                                "__timestamp","__operation_type",
                                "__sequence_number"]]
            )
        )
        po_services_conformed = po_services_conformed.join(
            ekpv_clean,
            on=["purchase_order_code","purchase_order_item"],
            how="left"
        )

    po_services_conformed = po_services_conformed.filter(
        F.col("purchase_order_code").isNotNull()
    )
    write_conformed(po_services_conformed, "purchase_order_services_details")
```

```python
# ============================================================
# STEP 15 — Quotation_Requests_Details
# EKAN — folder: eam-ecc-raw-tables
# ============================================================
ekan = safe_read(eam_path2, "EKAN")
if ekan: print("\nEKAN columns:", ekan.columns)

if ekan:
    quotation_conformed = (ekan
        .filter(F.col("MANDT") == MANDT)
        .dropDuplicates(["ANFNR","LIFNR"])
        .select(
            F.col("ANFNR").alias("rfq_number"),
            F.col("LIFNR").alias("supplier_code"),
            F.col("EKORG").alias("purchasing_organisation")
            if "EKORG" in ekan.columns
            else F.lit(None).cast("string").alias("purchasing_organisation"),
            F.col("EKGRP").alias("purchasing_group")
            if "EKGRP" in ekan.columns
            else F.lit(None).cast("string").alias("purchasing_group"),
            F.to_date(F.col("ERDAT"), "yyyyMMdd").alias("created_date")
            if "ERDAT" in ekan.columns
            else F.lit(None).cast("date").alias("created_date"),
            F.col("SPRAS").alias("language")
            if "SPRAS" in ekan.columns
            else F.lit(None).cast("string").alias("language"),
            F.col("BDART").alias("rfq_type")
            if "BDART" in ekan.columns
            else F.lit(None).cast("string").alias("rfq_type"),
            F.to_date(F.col("ANGDT"), "yyyyMMdd").alias("quotation_deadline_date")
            if "ANGDT" in ekan.columns
            else F.lit(None).cast("date").alias("quotation_deadline_date"),
            F.to_date(F.col("BNDDT"), "yyyyMMdd").alias("binding_period_end_date")
            if "BNDDT" in ekan.columns
            else F.lit(None).cast("date").alias("binding_period_end_date"),
            F.col("IHREZ").alias("our_reference")
            if "IHREZ" in ekan.columns
            else F.lit(None).cast("string").alias("our_reference"),
        )
        .filter(F.col("rfq_number").isNotNull())
    )
    write_conformed(quotation_conformed, "quotation_requests_details")
```

```python
# ============================================================
# STEP 16 — Quality Report — all EAM tables
# ============================================================
results = {
    "date_dimension"                                    : ("date",                          "date_dimension_conformed"),
    "invoice_voucher_details"                           : ("invoice_voucher_code",           "invoice_conformed"),
    "invoice_voucher_line_details"                      : ("invoice_voucher_code",           "invoice_line_conformed"),
    "organisation_details"                              : ("organisation_code",              "org_conformed"),
    "parts_details"                                     : ("material_code",                  "parts_conformed"),
    "parts_stock_details"                               : ("material_code",                  "stock_conformed"),
    "parts_store_details"                               : ("material_code",                  "store_conformed"),
    "purchase_order_details"                            : ("purchase_order_code",            "po_details_conformed"),
    "purchase_order_parts_details"                      : ("purchase_order_code",            "po_parts_conformed"),
    "purchase_order_receipt_details"                    : ("goods_receipt_document_number",  "po_receipt_conformed"),
    "purchase_order_receipt_packingslip_active_lines"   : ("goods_receipt_document_number",  "po_active_lines_conformed"),
    "purchase_order_receipts_packingslip_details"       : ("goods_receipt_document_number",  "packing_slip_conformed"),
    "purchase_order_service_receipts_details"           : ("service_entry_sheet_number",     "service_receipt_conformed"),
    "purchase_order_services_details"                   : ("purchase_order_code",            "po_services_conformed"),
    "quotation_requests_details"                        : ("rfq_number",                     "quotation_conformed"),
}

print(f"\n{'='*65}")
print(f"EAM Conformed Layer — Quality Report")
print(f"{'='*65}")
for name, (key, var) in results.items():
    try:
        df   = eval(var)
        total    = df.count()
        null_key = df.filter(F.col(key).isNull()).count()
        print(f"{name:<50} rows: {total:>8,}   null_key: {null_key:>5,}")
    except:
        print(f"{name:<50} ⚠️  not processed")
print(f"{'='*65}")
