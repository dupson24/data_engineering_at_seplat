```python
# ============================================================
# SRM Extended Tables — Bronze → Silver → Conformed
# ============================================================

raw_base       = "/mnt/sap-ecc-datasphere/sap-ecc-raw"
tx_path        = f"{raw_base}/transaction-data"
master_path    = f"{raw_base}/master-data"
ref_path       = f"{raw_base}/reference-and-config"
hr_path        = f"{raw_base}/hr"
pm_path        = f"{raw_base}/pm-asset-events"
eam_path       = f"{raw_base}/eam_ecc_raw_tables"    # underscore
srm_path       = f"{raw_base}/srm_ecc_raw_tables"    # srm specific
eam_path2      = f"{raw_base}/eam-ecc-raw-tables"    # hyphen
conformed_path = "/mnt/sap-ecc-datasphere/sap-ecc-conformed/srm"

MANDT = "010"
```

```python
# ============================================================
# UTILITY
# ============================================================
from pyspark.sql import functions as F
from pyspark.sql.window import Window

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
    try:
        return read_table(folder_path, table_name)
    except Exception as e:
        print(f"⚠️ {table_name} not available at {folder_path}: {e}")
        return None

def write_conformed(df, target_name):
    spark.conf.set("spark.databricks.delta.formatCheck.enabled", "false")
    (df.write.mode("overwrite").format("parquet")
       .option("compression", "snappy")
       .save(f"{conformed_path}/{target_name}"))
    spark.conf.set("spark.databricks.delta.formatCheck.enabled", "true")
    print(f"✅ {target_name}: {df.count():,} rows")
```

```python
# ============================================================
# STEP 1 — actdetails
# AFRU — folder: transaction-data
# Work order activity / confirmation details
# ============================================================
afru = safe_read(tx_path, "AFRU")
if afru: print("\nAFRU columns:", afru.columns)
```

```python
if afru:
    actdetails_conformed = (afru
        .filter(F.col("MANDT") == MANDT)
        .dropDuplicates(["RUECK","RMZHL"])
        .select(
            F.col("RUECK"),      # confirmation number — keep for rename
            F.col("RMZHL"),      # counter — keep for rename
            F.col("AUFNR").alias("work_order_number")
            if "AUFNR" in afru.columns
            else F.lit(None).cast("string").alias("work_order_number"),
            F.col("VORNR").alias("operation_number")
            if "VORNR" in afru.columns
            else F.lit(None).cast("string").alias("operation_number"),
            F.col("WERKS").alias("plant")
            if "WERKS" in afru.columns
            else F.lit(None).cast("string").alias("plant"),
            F.col("ARBID").alias("work_centre_id")
            if "ARBID" in afru.columns
            else F.lit(None).cast("string").alias("work_centre_id"),
            F.col("ISDD").alias("actual_start_date")
            if "ISDD" in afru.columns
            else F.lit(None).cast("string").alias("actual_start_date"),
            F.col("IEDD").alias("actual_end_date")
            if "IEDD" in afru.columns
            else F.lit(None).cast("string").alias("actual_end_date"),
            F.col("ISMNG").cast("decimal(18,3)").alias("confirmed_yield_quantity")
            if "ISMNG" in afru.columns
            else F.lit(None).cast("decimal(18,3)").alias("confirmed_yield_quantity"),
            F.col("ISMNW").cast("decimal(18,3)").alias("confirmed_work_quantity")
            if "ISMNW" in afru.columns
            else F.lit(None).cast("decimal(18,3)").alias("confirmed_work_quantity"),
            F.col("GMNGA").cast("decimal(18,3)").alias("confirmed_scrap_quantity")
            if "GMNGA" in afru.columns
            else F.lit(None).cast("decimal(18,3)").alias("confirmed_scrap_quantity"),
            F.col("BUDAT").alias("posting_date")
            if "BUDAT" in afru.columns
            else F.lit(None).cast("string").alias("posting_date"),
            F.col("ERNAM").alias("confirmed_by")
            if "ERNAM" in afru.columns
            else F.lit(None).cast("string").alias("confirmed_by"),
            F.col("STOKZ").alias("reversal_indicator")
            if "STOKZ" in afru.columns
            else F.lit(None).cast("string").alias("reversal_indicator"),
        )
        .withColumnRenamed("RUECK", "confirmation_number")
        .withColumnRenamed("RMZHL", "confirmation_counter")
        .filter(F.col("confirmation_number").isNotNull())
    )
    print(f"actdetails rows: {actdetails_conformed.count():,}")
    actdetails_conformed.show(5, truncate=False)
    write_conformed(actdetails_conformed, "actdetails")
```

```python
# ============================================================
# STEP 2 — actlog
# AFRU — same source, different perspective (activity log)
# ============================================================
if afru:
    actlog_conformed = (afru
        .filter(F.col("MANDT") == MANDT)
        .dropDuplicates(["RUECK","RMZHL"])
        .select(
            F.col("RUECK").alias("confirmation_number"),
            F.col("AUFNR").alias("work_order_number")
            if "AUFNR" in afru.columns
            else F.lit(None).cast("string").alias("work_order_number"),
            F.col("VORNR").alias("operation_number")
            if "VORNR" in afru.columns
            else F.lit(None).cast("string").alias("operation_number"),
            F.col("ISDD").alias("activity_date")
            if "ISDD" in afru.columns
            else F.lit(None).cast("string").alias("activity_date"),
            F.col("BUDAT").alias("posting_date")
            if "BUDAT" in afru.columns
            else F.lit(None).cast("string").alias("posting_date"),
            F.col("ERNAM").alias("created_by")
            if "ERNAM" in afru.columns
            else F.lit(None).cast("string").alias("created_by"),
            F.col("STOKZ").alias("reversal_indicator")
            if "STOKZ" in afru.columns
            else F.lit(None).cast("string").alias("reversal_indicator"),
            F.col("WERKS").alias("plant")
            if "WERKS" in afru.columns
            else F.lit(None).cast("string").alias("plant"),
            F.col("LMNGA").cast("decimal(18,3)").alias("activity_quantity")
            if "LMNGA" in afru.columns
            else F.lit(None).cast("decimal(18,3)").alias("activity_quantity"),
            F.col("MEINH").alias("unit_of_measure")
            if "MEINH" in afru.columns
            else F.lit(None).cast("string").alias("unit_of_measure"),
        )
        .filter(F.col("confirmation_number").isNotNull())
    )
    print(f"actlog rows: {actlog_conformed.count():,}")
    write_conformed(actlog_conformed, "actlog")
```

```python
# ============================================================
# STEP 3 — clients
# KNA1 — folder: master-data
# ADRP — folder: srm_ecc_raw_tables
# ============================================================
kna1 = safe_read(master_path, "KNA1")
adrp = safe_read(srm_path,    "ADRP")

if kna1: print("\nKNA1 columns:", kna1.columns)
if adrp: print("ADRP columns:", adrp.columns)
```

```python
if kna1:
    kna1_clean = (kna1
        .filter(F.col("MANDT") == MANDT)
        .dropDuplicates(["KUNNR"])
        .select(
            F.col("KUNNR"),
            F.col("NAME1").alias("client_name")
            if "NAME1" in kna1.columns
            else F.lit(None).cast("string").alias("client_name"),
            F.col("KTOKD").alias("account_group")
            if "KTOKD" in kna1.columns
            else F.lit(None).cast("string").alias("account_group"),
            F.col("LAND1").alias("country")
            if "LAND1" in kna1.columns
            else F.lit(None).cast("string").alias("country"),
            F.col("ORT01").alias("city")
            if "ORT01" in kna1.columns
            else F.lit(None).cast("string").alias("city"),
            F.col("STRAS").alias("street_address")
            if "STRAS" in kna1.columns
            else F.lit(None).cast("string").alias("street_address"),
            F.col("TELF1").alias("phone")
            if "TELF1" in kna1.columns
            else F.lit(None).cast("string").alias("phone"),
            F.col("SPERR").alias("block_indicator")
            if "SPERR" in kna1.columns
            else F.lit(None).cast("string").alias("block_indicator"),
            F.col("ADRNR").alias("address_number")
            if "ADRNR" in kna1.columns
            else F.lit(None).cast("string").alias("address_number"),
        )
    )

    clients_silver = kna1_clean

    if adrp:
        adrp_clean = (adrp
            .filter(F.col("MANDT") == MANDT)
            if "MANDT" in adrp.columns else adrp
        )
        adrp_clean = (adrp_clean
            .dropDuplicates(["ADDRNUMBER","PERSNUMBER"])
            .select(
                F.col("ADDRNUMBER").alias("address_number"),
                F.col("SMTP_ADDR").alias("email_address")
                if "SMTP_ADDR" in adrp.columns
                else F.lit(None).cast("string").alias("email_address"),
                F.col("FIRSTNAME").alias("contact_first_name")
                if "FIRSTNAME" in adrp.columns
                else F.lit(None).cast("string").alias("contact_first_name"),
                F.col("LASTNAME").alias("contact_last_name")
                if "LASTNAME" in adrp.columns
                else F.lit(None).cast("string").alias("contact_last_name"),
            )
        )
        clients_silver = clients_silver.join(
            adrp_clean, on="address_number", how="left"
        )

    clients_conformed = (clients_silver
        .withColumnRenamed("KUNNR", "client_code")
        .filter(F.col("client_code").isNotNull())
    )
    print(f"clients rows: {clients_conformed.count():,}")
    clients_conformed.show(5, truncate=False)
    write_conformed(clients_conformed, "clients")
```

```python
# ============================================================
# STEP 4 — docsup
# LFA1 — folder: sap-ecc-raw (root)
# CVP_SD_ADRNR — folder: srm_ecc_raw_tables
# ============================================================
lfa1        = safe_read(raw_base, "LFA1")
cvp_sd_adrnr= safe_read(srm_path, "CVP_SD_ADRNR")

if lfa1:         print("\nLFA1          columns:", lfa1.columns)
if cvp_sd_adrnr: print("CVP_SD_ADRNR  columns:", cvp_sd_adrnr.columns)
```

```python
if lfa1:
    lfa1_clean = (lfa1
        .filter(F.col("MANDT") == MANDT)
        .dropDuplicates(["LIFNR"])
        .select(
            F.col("LIFNR"),
            F.col("NAME1").alias("supplier_name")
            if "NAME1" in lfa1.columns
            else F.lit(None).cast("string").alias("supplier_name"),
            F.col("LAND1").alias("country")
            if "LAND1" in lfa1.columns
            else F.lit(None).cast("string").alias("country"),
            F.col("STRAS").alias("street_address")
            if "STRAS" in lfa1.columns
            else F.lit(None).cast("string").alias("street_address"),
            F.col("ORT01").alias("city")
            if "ORT01" in lfa1.columns
            else F.lit(None).cast("string").alias("city"),
            F.col("TELF1").alias("phone")
            if "TELF1" in lfa1.columns
            else F.lit(None).cast("string").alias("phone"),
            F.col("ADRNR").alias("address_number")
            if "ADRNR" in lfa1.columns
            else F.lit(None).cast("string").alias("address_number"),
            F.col("KTOKK").alias("account_group")
            if "KTOKK" in lfa1.columns
            else F.lit(None).cast("string").alias("account_group"),
        )
    )

    docsup_silver = lfa1_clean

    if cvp_sd_adrnr:
        print("CVP_SD_ADRNR columns:", cvp_sd_adrnr.columns)
        cvp_clean = (cvp_sd_adrnr
            .filter(F.col("MANDT") == MANDT)
            if "MANDT" in cvp_sd_adrnr.columns else cvp_sd_adrnr
        )
        addr_col = next((c for c in ["ADRNR","ADDRNUMBER"] if c in cvp_sd_adrnr.columns), None)
        if addr_col:
            cvp_clean = (cvp_clean
                .dropDuplicates([addr_col])
                .select(
                    F.col(addr_col).alias("address_number"),
                    *[F.col(c) for c in cvp_clean.columns
                      if c not in [addr_col,"MANDT","__timestamp",
                                   "__operation_type","__sequence_number"]]
                )
            )
            docsup_silver = docsup_silver.join(cvp_clean, on="address_number", how="left")

    docsup_conformed = (docsup_silver
        .withColumnRenamed("LIFNR", "supplier_code")
        .filter(F.col("supplier_code").isNotNull())
    )
    print(f"docsup rows: {docsup_conformed.count():,}")
    docsup_conformed.show(5, truncate=False)
    write_conformed(docsup_conformed, "docsup")
```

```python
# ============================================================
# STEP 5 — itemcat
# T023 — folder: reference-and-config
# MARA — folder: master-data
# ============================================================
t023 = safe_read(ref_path,    "T023")
mara = safe_read(master_path, "MARA")

if t023: print("\nT023 columns:", t023.columns)
if mara: print("MARA columns:", mara.columns)
```

```python
if t023:
    t023_clean = (t023
        .filter(F.col("MANDT") == MANDT)
        if "MANDT" in t023.columns else t023
    )
    t023_clean = (t023_clean
        .dropDuplicates(["MATKL"])
        .select(
            F.col("MATKL"),
            F.col("WGBEZ").alias("material_group_description")
            if "WGBEZ" in t023.columns
            else F.lit(None).cast("string").alias("material_group_description"),
            F.col("WGBEZ60").alias("material_group_description_long")
            if "WGBEZ60" in t023.columns
            else F.lit(None).cast("string").alias("material_group_description_long"),
        )
    )

    itemcat_silver = t023_clean

    if mara:
        mara_clean = (mara
            .filter(F.col("MANDT") == MANDT)
            .dropDuplicates(["MATKL"])
            .select(
                F.col("MATKL"),
                F.col("MTART").alias("material_type")
                if "MTART" in mara.columns
                else F.lit(None).cast("string").alias("material_type"),
                F.col("MEINS").alias("base_unit_of_measure")
                if "MEINS" in mara.columns
                else F.lit(None).cast("string").alias("base_unit_of_measure"),
            )
        )
        itemcat_silver = itemcat_silver.join(mara_clean, on="MATKL", how="left")

    itemcat_conformed = (itemcat_silver
        .withColumnRenamed("MATKL", "material_group_code")
        .filter(F.col("material_group_code").isNotNull())
    )
    print(f"itemcat rows: {itemcat_conformed.count():,}")
    itemcat_conformed.show(5, truncate=False)
    write_conformed(itemcat_conformed, "itemcat")
```

```python
# ============================================================
# STEP 6 — items
# MARA + MARC — folder: master-data
# MBEW        — folder: eam_ecc_raw_tables
# ============================================================
mara = safe_read(master_path, "MARA")
marc = safe_read(master_path, "MARC")
mbew = safe_read(eam_path,    "MBEW")

if mara: print("\nMARA columns:", mara.columns)
if marc: print("MARC columns:", marc.columns)
if mbew: print("MBEW columns:", mbew.columns)
```

```python
if mara:
    mara_clean = (mara
        .filter(F.col("MANDT") == MANDT)
        .dropDuplicates(["MATNR"])
        .select(
            F.col("MATNR"),
            F.col("MATKL").alias("material_group"),
            F.col("MTART").alias("material_type"),
            F.col("MEINS").alias("base_unit_of_measure"),
            F.col("MBRSH").alias("industry_sector")
            if "MBRSH" in mara.columns
            else F.lit(None).cast("string").alias("industry_sector"),
            F.col("BRGEW").cast("decimal(18,3)").alias("gross_weight")
            if "BRGEW" in mara.columns
            else F.lit(None).cast("decimal(18,3)").alias("gross_weight"),
            F.col("GEWEI").alias("weight_unit")
            if "GEWEI" in mara.columns
            else F.lit(None).cast("string").alias("weight_unit"),
            F.to_date(F.col("ERSDA"), "yyyyMMdd").alias("created_date")
            if "ERSDA" in mara.columns
            else F.lit(None).cast("date").alias("created_date"),
        )
    )

    items_silver = mara_clean

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
                F.col("MINBE").cast("decimal(18,3)").alias("reorder_point")
                if "MINBE" in marc.columns
                else F.lit(None).cast("decimal(18,3)").alias("reorder_point"),
                F.col("EISBE").cast("decimal(18,3)").alias("safety_stock")
                if "EISBE" in marc.columns
                else F.lit(None).cast("decimal(18,3)").alias("safety_stock"),
                F.col("MABST").cast("decimal(18,3)").alias("maximum_stock")
                if "MABST" in marc.columns
                else F.lit(None).cast("decimal(18,3)").alias("maximum_stock"),
            )
        )
        items_silver = items_silver.join(marc_clean, on="MATNR", how="left")

    if mbew:
        mbew_clean = (mbew
            .filter(F.col("MANDT") == MANDT)
            .dropDuplicates(["MATNR","BWKEY"])
            .select(
                F.col("MATNR"),
                F.col("BWKEY").alias("valuation_area"),
                F.col("VERPR").cast("decimal(18,4)").alias("moving_average_price")
                if "VERPR" in mbew.columns
                else F.lit(None).cast("decimal(18,4)").alias("moving_average_price"),
                F.col("STPRS").cast("decimal(18,4)").alias("standard_price")
                if "STPRS" in mbew.columns
                else F.lit(None).cast("decimal(18,4)").alias("standard_price"),
                F.col("LBKUM").cast("decimal(18,3)").alias("total_stock_quantity")
                if "LBKUM" in mbew.columns
                else F.lit(None).cast("decimal(18,3)").alias("total_stock_quantity"),
                F.col("SALK3").cast("decimal(18,2)").alias("total_stock_value")
                if "SALK3" in mbew.columns
                else F.lit(None).cast("decimal(18,2)").alias("total_stock_value"),
            )
        )
        items_silver = items_silver.join(mbew_clean, on="MATNR", how="left")

    items_conformed = (items_silver
        .withColumnRenamed("MATNR", "material_code")
        .filter(F.col("material_code").isNotNull())
    )
    print(f"items rows: {items_conformed.count():,}")
    items_conformed.show(5, truncate=False)
    write_conformed(items_conformed, "items")
```

```python
# ============================================================
# STEP 7 — locations
# T001W — folder: reference-and-config
# ILOA  — folder: pm-asset-events
# ============================================================
t001w = safe_read(ref_path, "T001W")
iloa  = safe_read(pm_path,  "ILOA")

if t001w: print("\nT001W columns:", t001w.columns)
if iloa:  print("ILOA  columns:", iloa.columns)
```

```python
if t001w:
    t001w_clean = (t001w
        .filter(F.col("MANDT") == MANDT)
        if "MANDT" in t001w.columns else t001w
    )
    t001w_clean = (t001w_clean
        .dropDuplicates(["WERKS"])
        .select(
            F.col("WERKS"),
            F.col("NAME1").alias("location_name")
            if "NAME1" in t001w.columns
            else F.lit(None).cast("string").alias("location_name"),
            F.col("STRAS").alias("street_address")
            if "STRAS" in t001w.columns
            else F.lit(None).cast("string").alias("street_address"),
            F.col("ORT01").alias("city")
            if "ORT01" in t001w.columns
            else F.lit(None).cast("string").alias("city"),
            F.col("LAND1").alias("country")
            if "LAND1" in t001w.columns
            else F.lit(None).cast("string").alias("country"),
            F.col("BUKRS").alias("company_code")
            if "BUKRS" in t001w.columns
            else F.lit(None).cast("string").alias("company_code"),
        )
    )

    locations_silver = t001w_clean

    if iloa:
        iloa_clean = (iloa
            .filter(F.col("MANDT") == MANDT)
            .dropDuplicates(["IWERK"])
            .select(
                F.col("IWERK").alias("WERKS"),
                F.col("TPLNR").alias("functional_location")
                if "TPLNR" in iloa.columns
                else F.lit(None).cast("string").alias("functional_location"),
                F.col("STORT").alias("location_description")
                if "STORT" in iloa.columns
                else F.lit(None).cast("string").alias("location_description"),
            )
        )
        locations_silver = locations_silver.join(iloa_clean, on="WERKS", how="left")

    locations_conformed = (locations_silver
        .withColumnRenamed("WERKS", "location_code")
        .filter(F.col("location_code").isNotNull())
    )
    print(f"locations rows: {locations_conformed.count():,}")
    locations_conformed.show(5, truncate=False)
    write_conformed(locations_conformed, "locations")
```

```python
# ============================================================
# STEP 8 — nations
# T005  — folder: srm_ecc_raw_tables
# T005T — folder: srm_ecc_raw_tables
# ============================================================
t005  = safe_read(srm_path, "T005")
t005t = safe_read(srm_path, "T005T")

if t005:  print("\nT005  columns:", t005.columns)
if t005t: print("T005T columns:", t005t.columns)
```

```python
if t005:
    t005_clean = (t005
        .filter(F.col("MANDT") == MANDT)
        if "MANDT" in t005.columns else t005
    )
    t005_clean = (t005_clean
        .dropDuplicates(["LAND1"])
        .select(
            F.col("LAND1"),
            F.col("XEGLD").alias("eu_member_flag")
            if "XEGLD" in t005.columns
            else F.lit(None).cast("string").alias("eu_member_flag"),
            F.col("WAERS").alias("currency")
            if "WAERS" in t005.columns
            else F.lit(None).cast("string").alias("currency"),
        )
    )

    nations_silver = t005_clean

    if t005t:
        t005t_clean = (t005t
            .filter(F.col("MANDT") == MANDT)
            if "MANDT" in t005t.columns else t005t
        )
        t005t_clean = (t005t_clean
            .filter(F.col("SPRAS") == "EN"
                    if "SPRAS" in t005t.columns else F.lit(True))
            .dropDuplicates(["LAND1"])
            .select(
                F.col("LAND1"),
                F.col("LANDX").alias("country_name")
                if "LANDX" in t005t.columns
                else F.lit(None).cast("string").alias("country_name"),
                F.col("NATIO").alias("nationality")
                if "NATIO" in t005t.columns
                else F.lit(None).cast("string").alias("nationality"),
            )
        )
        nations_silver = nations_silver.join(t005t_clean, on="LAND1", how="left")

    nations_conformed = (nations_silver
        .withColumnRenamed("LAND1", "country_code")
        .filter(F.col("country_code").isNotNull())
    )
    print(f"nations rows: {nations_conformed.count():,}")
    nations_conformed.show(5, truncate=False)
    write_conformed(nations_conformed, "nations")
```

```python
# ============================================================
# STEP 9 — newdepts
# HRP1000 — folder: srm_ecc_raw_tables
# CSKS    — folder: master-data
# ============================================================
hrp1000 = safe_read(srm_path,    "HRP1000")
csks    = safe_read(master_path, "CSKS")

if hrp1000: print("\nHRP1000 columns:", hrp1000.columns)
if csks:    print("CSKS    columns:", csks.columns)
```

```python
if hrp1000:
    hrp1000_clean = (hrp1000
        .filter(F.col("MANDT") == MANDT)
        if "MANDT" in hrp1000.columns else hrp1000
    )
    hrp1000_clean = (hrp1000_clean
        .filter(F.col("OTYPE") == "O")  # O = org unit
        .dropDuplicates(["OBJID"])
        .select(
            F.col("OBJID").alias("org_unit_id"),
            F.col("SHORT").alias("org_unit_short_name")
            if "SHORT" in hrp1000.columns
            else F.lit(None).cast("string").alias("org_unit_short_name"),
            F.col("STEXT").alias("org_unit_description")
            if "STEXT" in hrp1000.columns
            else F.lit(None).cast("string").alias("org_unit_description"),
            F.col("BEGDA").alias("valid_from")
            if "BEGDA" in hrp1000.columns
            else F.lit(None).cast("string").alias("valid_from"),
            F.col("ENDDA").alias("valid_to")
            if "ENDDA" in hrp1000.columns
            else F.lit(None).cast("string").alias("valid_to"),
        )
    )

    newdepts_silver = hrp1000_clean

    if csks:
        csks_clean = (csks
            .filter(F.col("MANDT") == MANDT)
            .dropDuplicates(["KOSTL","KOKRS"])
            .select(
                F.col("KOSTL").alias("cost_centre_code"),
                F.col("KOKRS").alias("controlling_area"),
                F.col("KTEXT").alias("cost_centre_name")
                if "KTEXT" in csks.columns
                else F.lit(None).cast("string").alias("cost_centre_name"),
                F.col("VERAK").alias("responsible_person")
                if "VERAK" in csks.columns
                else F.lit(None).cast("string").alias("responsible_person"),
                F.col("WERKS").alias("plant")
                if "WERKS" in csks.columns
                else F.lit(None).cast("string").alias("plant"),
            )
        )
        # Bring cost centres as supplementary info (not direct join to HRP1000)
        print(f"CSKS rows available: {csks_clean.count():,}")
        # Union dept + cost centre as combined departments view
        csks_as_dept = csks_clean.select(
            F.col("cost_centre_code").alias("org_unit_id"),
            F.col("cost_centre_name").alias("org_unit_short_name"),
            F.col("cost_centre_name").alias("org_unit_description"),
            F.lit(None).cast("string").alias("valid_from"),
            F.lit(None).cast("string").alias("valid_to"),
        )
        newdepts_silver = newdepts_silver.unionByName(csks_as_dept)

    newdepts_conformed = newdepts_silver.filter(F.col("org_unit_id").isNotNull())
    print(f"newdepts rows: {newdepts_conformed.count():,}")
    newdepts_conformed.show(5, truncate=False)
    write_conformed(newdepts_conformed, "newdepts")
```

```python
# ============================================================
# STEP 10 — newstock
# MKPF + MSEG — folder: transaction-data
# ============================================================
mkpf = safe_read(tx_path, "MKPF")
mseg = safe_read(tx_path, "MSEG")

if mkpf: print("\nMKPF columns:", mkpf.columns)
if mseg: print("MSEG columns:", mseg.columns)
```

```python
if mkpf and mseg:
    mkpf_clean = (mkpf
        .filter(F.col("MANDT") == MANDT)
        .dropDuplicates(["MBLNR","MJAHR"])
        .select(
            F.col("MBLNR"),
            F.col("MJAHR"),
            F.to_date(F.col("BUDAT"), "yyyyMMdd").alias("posting_date")
            if "BUDAT" in mkpf.columns
            else F.lit(None).cast("date").alias("posting_date"),
            F.col("USNAM").alias("created_by")
            if "USNAM" in mkpf.columns
            else F.lit(None).cast("string").alias("created_by"),
        )
    )

    mseg_clean = (mseg
        .filter(F.col("MANDT") == MANDT)
        .filter(F.col("BWART").isin(["101","102","501","502"])
                if "BWART" in mseg.columns else F.lit(True))
        .dropDuplicates(["MBLNR","MJAHR","ZEILE"])
        .select(
            F.col("MBLNR"),
            F.col("MJAHR"),
            F.col("ZEILE").alias("document_item"),
            F.col("MATNR").alias("material_code"),
            F.col("WERKS").alias("plant"),
            F.col("LGORT").alias("storage_location")
            if "LGORT" in mseg.columns
            else F.lit(None).cast("string").alias("storage_location"),
            F.col("BWART").alias("movement_type")
            if "BWART" in mseg.columns
            else F.lit(None).cast("string").alias("movement_type"),
            F.col("MENGE").cast("decimal(18,3)").alias("quantity")
            if "MENGE" in mseg.columns
            else F.lit(None).cast("decimal(18,3)").alias("quantity"),
            F.col("MEINS").alias("unit_of_measure")
            if "MEINS" in mseg.columns
            else F.lit(None).cast("string").alias("unit_of_measure"),
            F.col("DMBTR").cast("decimal(18,2)").alias("amount_local_currency")
            if "DMBTR" in mseg.columns
            else F.lit(None).cast("decimal(18,2)").alias("amount_local_currency"),
            F.col("EBELN").alias("purchase_order_number")
            if "EBELN" in mseg.columns
            else F.lit(None).cast("string").alias("purchase_order_number"),
            F.col("LIFNR").alias("supplier_code")
            if "LIFNR" in mseg.columns
            else F.lit(None).cast("string").alias("supplier_code"),
        )
    )

    newstock_silver = mseg_clean.join(mkpf_clean, on=["MBLNR","MJAHR"], how="left")

    newstock_conformed = (newstock_silver
        .withColumnRenamed("MBLNR", "material_document_number")
        .withColumnRenamed("MJAHR", "material_document_year")
        .filter(F.col("material_document_number").isNotNull())
    )
    print(f"newstock rows: {newstock_conformed.count():,}")
    newstock_conformed.show(5, truncate=False)
    write_conformed(newstock_conformed, "newstock")
```

```python
# ============================================================
# STEP 11 — pendingpos
# EKKO + EKPO — folder: transaction-data
# ============================================================
ekko = safe_read(tx_path, "EKKO")
ekpo = safe_read(tx_path, "EKPO")

if ekko: print("\nEKKO columns:", ekko.columns)
if ekpo: print("EKPO columns:", ekpo.columns)
```

```python
if ekko and ekpo:
    ekko_clean = (ekko
        .filter(F.col("MANDT") == MANDT)
        .filter(F.col("LOEKZ") != "L"
                if "LOEKZ" in ekko.columns else F.lit(True))
        .dropDuplicates(["EBELN"])
        .select(
            F.col("EBELN"),
            F.col("LIFNR").alias("supplier_code"),
            F.col("EKORG").alias("purchasing_org"),
            F.col("EKGRP").alias("purchasing_group"),
            F.col("BSART").alias("po_type"),
            F.col("WAERS").alias("currency"),
            F.to_date(F.col("BEDAT"), "yyyyMMdd").alias("po_date"),
            F.col("ERNAM").alias("created_by")
            if "ERNAM" in ekko.columns
            else F.lit(None).cast("string").alias("created_by"),
        )
    )

    delivery_date_col = next(
        (c for c in ["EINDT","EILDT","AGDAT","PRDAT"] if c in ekpo.columns), None
    )
    print(f"EKPO delivery date column: {delivery_date_col}")

    ekpo_clean = (ekpo
        .filter(F.col("MANDT") == MANDT)
        .filter(F.col("ELIKZ") != "X"
                if "ELIKZ" in ekpo.columns else F.lit(True))
        .dropDuplicates(["EBELN","EBELP"])
        .select(
            F.col("EBELN"),
            F.col("EBELP").alias("po_item"),
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
        )
    )

    pendingpos_silver = ekpo_clean.join(ekko_clean, on="EBELN", how="left")

    pendingpos_conformed = (pendingpos_silver
        .withColumnRenamed("EBELN", "purchase_order_number")
        .filter(F.col("purchase_order_number").isNotNull())
    )
    print(f"pendingpos rows: {pendingpos_conformed.count():,}")
    pendingpos_conformed.show(5, truncate=False)
    write_conformed(pendingpos_conformed, "pendingpos")
```

```python
# ============================================================
# STEP 12 — pendingrequests
# EBAN — folder: transaction-data
# ============================================================
eban = safe_read(tx_path, "EBAN")
if eban: print("\nEBAN columns:", eban.columns)
```

```python
if eban:
    pendingrequests_conformed = (eban
        .filter(F.col("MANDT") == MANDT)
        .filter(F.col("LOEKZ") != "L"
                if "LOEKZ" in eban.columns else F.lit(True))
        .dropDuplicates(["BANFN","BNFPO"])
        .select(
            F.col("BANFN"),
            F.col("BNFPO").alias("pr_item"),
            F.col("MATNR").alias("material_code")
            if "MATNR" in eban.columns
            else F.lit(None).cast("string").alias("material_code"),
            F.col("TXZ01").alias("item_description")
            if "TXZ01" in eban.columns
            else F.lit(None).cast("string").alias("item_description"),
            F.col("MENGE").cast("decimal(18,3)").alias("requested_quantity")
            if "MENGE" in eban.columns
            else F.lit(None).cast("decimal(18,3)").alias("requested_quantity"),
            F.col("MEINS").alias("unit_of_measure")
            if "MEINS" in eban.columns
            else F.lit(None).cast("string").alias("unit_of_measure"),
            F.col("PREIS").cast("decimal(18,2)").alias("estimated_price")
            if "PREIS" in eban.columns
            else F.lit(None).cast("decimal(18,2)").alias("estimated_price"),
            F.col("WERKS").alias("plant")
            if "WERKS" in eban.columns
            else F.lit(None).cast("string").alias("plant"),
            F.col("KOSTL").alias("cost_centre")
            if "KOSTL" in eban.columns
            else F.lit(None).cast("string").alias("cost_centre"),
            F.to_date(F.col("BADAT"), "yyyyMMdd").alias("requisition_date")
            if "BADAT" in eban.columns
            else F.lit(None).cast("date").alias("requisition_date"),
            F.col("AFNAM").alias("requested_by")
            if "AFNAM" in eban.columns
            else F.lit(None).cast("string").alias("requested_by"),
            F.col("FRGKZ").alias("release_status")
            if "FRGKZ" in eban.columns
            else F.lit(None).cast("string").alias("release_status"),
            F.col("MATKL").alias("material_group")
            if "MATKL" in eban.columns
            else F.lit(None).cast("string").alias("material_group"),
            F.col("EBELN").alias("purchase_order_reference")
            if "EBELN" in eban.columns
            else F.lit(None).cast("string").alias("purchase_order_reference"),
        )
        .withColumnRenamed("BANFN", "requisition_number")
        .filter(F.col("requisition_number").isNotNull())
    )
    print(f"pendingrequests rows: {pendingrequests_conformed.count():,}")
    pendingrequests_conformed.show(5, truncate=False)
    write_conformed(pendingrequests_conformed, "pendingrequests")
```

```python
# ============================================================
# STEP 13 — settings
# T001 — folder: master-data
# ============================================================
t001 = safe_read(master_path, "T001")
if t001: print("\nT001 columns:", t001.columns)
```

```python
if t001:
    settings_conformed = (t001
        .filter(F.col("MANDT") == MANDT)
        if "MANDT" in t001.columns else t001
    )
    settings_conformed = (settings_conformed
        .dropDuplicates(["BUKRS"])
        .select(
            F.col("BUKRS").alias("company_code"),
            F.col("BUTXT").alias("company_name")
            if "BUTXT" in t001.columns
            else F.lit(None).cast("string").alias("company_name"),
            F.col("WAERS").alias("currency")
            if "WAERS" in t001.columns
            else F.lit(None).cast("string").alias("currency"),
            F.col("LAND1").alias("country")
            if "LAND1" in t001.columns
            else F.lit(None).cast("string").alias("country"),
            F.col("SPRAS").alias("language")
            if "SPRAS" in t001.columns
            else F.lit(None).cast("string").alias("language"),
            F.col("PERIV").alias("fiscal_year_variant")
            if "PERIV" in t001.columns
            else F.lit(None).cast("string").alias("fiscal_year_variant"),
            F.col("KTOPL").alias("chart_of_accounts")
            if "KTOPL" in t001.columns
            else F.lit(None).cast("string").alias("chart_of_accounts"),
            F.col("KOKFI").alias("controlling_area")
            if "KOKFI" in t001.columns
            else F.lit(None).cast("string").alias("controlling_area"),
        )
        .filter(F.col("company_code").isNotNull())
    )
    print(f"settings rows: {settings_conformed.count():,}")
    settings_conformed.show(5, truncate=False)
    write_conformed(settings_conformed, "settings")
```

```python
# ============================================================
# STEP 14 — stowners
# PA0001 — folder: master-data
# PA0002 — folder: hr
# ============================================================
pa0001 = safe_read(master_path, "PA0001")
pa0002 = safe_read(hr_path,     "PA0002")

if pa0001: print("\nPA0001 columns:", pa0001.columns)
if pa0002: print("PA0002 columns:", pa0002.columns)
```

```python
if pa0002:
    pa0002_clean = (pa0002
        .filter(F.col("MANDT") == MANDT)
        .dropDuplicates(["PERNR"])
        .select(
            F.col("PERNR"),
            F.col("VORNA").alias("first_name"),
            F.col("NACHN").alias("last_name"),
            F.to_date(F.col("GBDAT"), "yyyyMMdd").alias("birth_date"),
            F.col("GBLND").alias("country")
            if "GBLND" in pa0002.columns
            else F.lit(None).cast("string").alias("country"),
            F.col("GESCH").alias("gender")
            if "GESCH" in pa0002.columns
            else F.lit(None).cast("string").alias("gender"),
        )
    )

    stowners_silver = pa0002_clean

    if pa0001:
        pa0001_clean = (pa0001
            .filter(F.col("MANDT") == MANDT)
            .dropDuplicates(["PERNR"])
            .select(
                F.col("PERNR"),
                F.col("PLANS").alias("position")
                if "PLANS" in pa0001.columns
                else F.lit(None).cast("string").alias("position"),
                F.col("KOSTL").alias("cost_centre")
                if "KOSTL" in pa0001.columns
                else F.lit(None).cast("string").alias("cost_centre"),
                F.col("ORGEH").alias("org_unit")
                if "ORGEH" in pa0001.columns
                else F.lit(None).cast("string").alias("org_unit"),
                F.col("WERKS").alias("plant")
                if "WERKS" in pa0001.columns
                else F.lit(None).cast("string").alias("plant"),
                F.to_date(F.col("BEGDA"), "yyyyMMdd").alias("hire_date")
                if "BEGDA" in pa0001.columns
                else F.lit(None).cast("date").alias("hire_date"),
                F.col("STAT2").alias("employment_status")
                if "STAT2" in pa0001.columns
                else F.lit(None).cast("string").alias("employment_status"),
                F.col("USRID").alias("sap_user_id")
                if "USRID" in pa0001.columns
                else F.lit(None).cast("string").alias("sap_user_id"),
            )
        )
        stowners_silver = stowners_silver.join(pa0001_clean, on="PERNR", how="left")

    stowners_conformed = (stowners_silver
        .withColumnRenamed("PERNR", "employee_code")
        .select(
            F.col("employee_code"),
            F.concat_ws(" ", F.col("first_name"), F.col("last_name")).alias("full_name"),
            F.col("position").alias("job_title")
            if "position" in stowners_silver.columns
            else F.lit(None).cast("string").alias("job_title"),
            F.col("cost_centre")
            if "cost_centre" in stowners_silver.columns
            else F.lit(None).cast("string").alias("cost_centre"),
            F.col("org_unit")
            if "org_unit" in stowners_silver.columns
            else F.lit(None).cast("string").alias("org_unit"),
            F.col("plant").alias("location")
            if "plant" in stowners_silver.columns
            else F.lit(None).cast("string").alias("location"),
            F.col("hire_date")
            if "hire_date" in stowners_silver.columns
            else F.lit(None).cast("date").alias("hire_date"),
            F.col("birth_date"),
            F.col("country"),
            F.col("gender"),
            F.when(F.col("employment_status") == "3", "Active")
             .otherwise("Inactive").alias("status")
            if "employment_status" in stowners_silver.columns
            else F.lit("Unknown").alias("status"),
            F.col("sap_user_id").alias("username")
            if "sap_user_id" in stowners_silver.columns
            else F.lit(None).cast("string").alias("username"),
        )
        .filter(F.col("employee_code").isNotNull())
    )
    print(f"stowners rows: {stowners_conformed.count():,}")
    stowners_conformed.show(5, truncate=False)
    write_conformed(stowners_conformed, "stowners")
```

```python
# ============================================================
# STEP 15 — stowner2
# PA0001 + PA0002 + PA0006 — full employee with address
# ============================================================
pa0006 = safe_read(hr_path, "PA0006")
if pa0006: print("\nPA0006 columns:", pa0006.columns)
```

```python
if pa0002:
    # Start from stowners_silver (already has PA0001 + PA0002)
    stowner2_silver = stowners_silver.copy() \
        if hasattr(stowners_silver, "copy") else stowners_silver

    if pa0006:
        pa0006_clean = (pa0006
            .filter(F.col("MANDT") == MANDT)
            .dropDuplicates(["PERNR"])
            .select(
                F.col("PERNR"),
                F.col("STRAS").alias("street_address")
                if "STRAS" in pa0006.columns
                else F.lit(None).cast("string").alias("street_address"),
                F.col("ORT01").alias("city")
                if "ORT01" in pa0006.columns
                else F.lit(None).cast("string").alias("city"),
                F.col("LAND1").alias("address_country")
                if "LAND1" in pa0006.columns
                else F.lit(None).cast("string").alias("address_country"),
                F.col("PSTLZ").alias("postal_code")
                if "PSTLZ" in pa0006.columns
                else F.lit(None).cast("string").alias("postal_code"),
            )
        )
        stowner2_silver = stowners_silver.join(
            pa0006_clean, on="PERNR", how="left"
        )

    stowner2_conformed = (stowner2_silver
        .withColumnRenamed("PERNR", "employee_code")
        if "PERNR" in stowner2_silver.columns
        else stowner2_silver.withColumnRenamed("employee_code","employee_code")
    )

    # If PERNR already renamed to employee_code in stowners step re-read
    if "employee_code" not in stowner2_silver.columns:
        stowner2_silver2 = stowners_silver
        if pa0006:
            stowner2_silver2 = stowners_silver.join(pa0006_clean, on="PERNR", how="left")
        stowner2_conformed = (stowner2_silver2
            .withColumnRenamed("PERNR", "employee_code")
            .filter(F.col("employee_code").isNotNull())
        )
    else:
        stowner2_conformed = stowner2_conformed.filter(F.col("employee_code").isNotNull())

    print(f"stowner2 rows: {stowner2_conformed.count():,}")
    stowner2_conformed.show(5, truncate=False)
    write_conformed(stowner2_conformed, "stowner2")
```

```python
# ============================================================
# STEP 16 — vendacct
# LFB1 — folder: master-data
# LFBK — folder: sap-ecc-raw (root)
# ============================================================
lfb1 = safe_read(master_path, "LFB1")
lfbk = safe_read(raw_base,    "LFBK")

if lfb1: print("\nLFB1 columns:", lfb1.columns)
if lfbk: print("LFBK columns:", lfbk.columns)
```

```python
if lfb1:
    lfb1_clean = (lfb1
        .filter(F.col("MANDT") == MANDT)
        .dropDuplicates(["LIFNR","BUKRS"])
        .select(
            F.col("LIFNR"),
            F.col("BUKRS").alias("company_code"),
            F.col("AKONT").alias("reconciliation_account")
            if "AKONT" in lfb1.columns
            else F.lit(None).cast("string").alias("reconciliation_account"),
            F.col("ZTERM").alias("payment_terms")
            if "ZTERM" in lfb1.columns
            else F.lit(None).cast("string").alias("payment_terms"),
            F.col("WAERS").alias("currency")
            if "WAERS" in lfb1.columns
            else F.lit(None).cast("string").alias("currency"),
            F.col("ZWELS").alias("payment_methods")
            if "ZWELS" in lfb1.columns
            else F.lit(None).cast("string").alias("payment_methods"),
            F.col("ZAHLS").alias("block_payment_flag")
            if "ZAHLS" in lfb1.columns
            else F.lit(None).cast("string").alias("block_payment_flag"),
        )
    )

    vendacct_silver = lfb1_clean

    if lfbk:
        lfbk_clean = (lfbk
            .filter(F.col("MANDT") == MANDT)
            .dropDuplicates(["LIFNR","BUKRS"])
            .select(
                F.col("LIFNR"),
                F.col("BUKRS").alias("company_code"),
                F.col("BANKL").alias("bank_sort_code")
                if "BANKL" in lfbk.columns
                else F.lit(None).cast("string").alias("bank_sort_code"),
                F.col("BANKN").alias("bank_account_number")
                if "BANKN" in lfbk.columns
                else F.lit(None).cast("string").alias("bank_account_number"),
                F.col("BKONT").alias("bank_account_type")
                if "BKONT" in lfbk.columns
                else F.lit(None).cast("string").alias("bank_account_type"),
                F.col("BANKS").alias("bank_country")
                if "BANKS" in lfbk.columns
                else F.lit(None).cast("string").alias("bank_country"),
            )
        )
        vendacct_silver = lfb1_clean.join(
            lfbk_clean, on=["LIFNR","company_code"], how="left"
        )

    vendacct_conformed = (vendacct_silver
        .withColumnRenamed("LIFNR", "vendor_code")
        .filter(F.col("vendor_code").isNotNull())
    )
    print(f"vendacct rows: {vendacct_conformed.count():,}")
    vendacct_conformed.show(5, truncate=False)
    write_conformed(vendacct_conformed, "vendacct")
```

```python
# ============================================================
# STEP 17 — vendapps
# SWWWIHEAD — folder: srm_ecc_raw_tables
# ============================================================
swwwihead = safe_read(srm_path, "SWWWIHEAD")
if swwwihead: print("\nSWWWIHEAD columns:", swwwihead.columns)
```

```python
if swwwihead:
    mandt_col = "MANDT" if "MANDT" in swwwihead.columns else None
    swww_clean = (swwwihead
        .filter(F.col("MANDT") == MANDT)
        if mandt_col else swwwihead
    )
    key_col = next((c for c in ["WI_ID","WIID","ID"] if c in swwwihead.columns), None)
    print(f"SWWWIHEAD key column: {key_col}")

    if key_col:
        vendapps_conformed = (swww_clean
            .dropDuplicates([key_col])
            .select(
                F.col(key_col).alias("workflow_id"),
                *[F.col(c) for c in swww_clean.columns
                  if c not in [key_col,"MANDT","__timestamp",
                               "__operation_type","__sequence_number"]]
            )
            .filter(F.col("workflow_id").isNotNull())
        )
        print(f"vendapps rows: {vendapps_conformed.count():,}")
        vendapps_conformed.show(5, truncate=False)
        write_conformed(vendapps_conformed, "vendapps")
    else:
        print("⚠️ No key column found in SWWWIHEAD — inspect columns above")
```

```python
# ============================================================
# STEP 18 — vendcat
# CRMKTOKK — folder: srm_ecc_raw_tables
# T077K    — folder: srm_ecc_raw_tables
# ============================================================
crmktokk = safe_read(srm_path, "CRMKTOKK")
t077k    = safe_read(srm_path, "T077K")

if crmktokk: print("\nCRMKTOKK columns:", crmktokk.columns)
if t077k:    print("T077K    columns:", t077k.columns)
```

```python
vendcat_dfs = []

if crmktokk:
    crm_clean = (crmktokk
        .filter(F.col("MANDT") == MANDT)
        if "MANDT" in crmktokk.columns else crmktokk
    )
    key_col = next((c for c in ["KTOKK","KTOKD","CODE"] if c in crmktokk.columns), None)
    if key_col:
        crm_clean = (crm_clean
            .dropDuplicates([key_col])
            .select(
                F.col(key_col).alias("vendor_category_code"),
                *[F.col(c) for c in crm_clean.columns
                  if c not in [key_col,"MANDT","__timestamp",
                               "__operation_type","__sequence_number"]]
            )
        )
        vendcat_dfs.append(crm_clean)

if t077k:
    t077k_clean = (t077k
        .filter(F.col("MANDT") == MANDT)
        if "MANDT" in t077k.columns else t077k
    )
    key_col2 = next((c for c in ["KTOKK","KTOKD"] if c in t077k.columns), None)
    if key_col2:
        t077k_cols = [c for c in t077k_clean.columns
                      if c not in [key_col2,"MANDT","__timestamp",
                                   "__operation_type","__sequence_number"]]
        t077k_clean = (t077k_clean
            .dropDuplicates([key_col2])
            .select(
                F.col(key_col2).alias("vendor_category_code"),
                *[F.col(c) for c in t077k_cols]
            )
        )
        # If CRMKTOKK already loaded join, else use standalone
        if vendcat_dfs:
            vendcat_dfs[0] = vendcat_dfs[0].join(
                t077k_clean, on="vendor_category_code", how="left"
            )
        else:
            vendcat_dfs.append(t077k_clean)

if vendcat_dfs:
    vendcat_conformed = vendcat_dfs[0].filter(
        F.col("vendor_category_code").isNotNull()
    )
    print(f"vendcat rows: {vendcat_conformed.count():,}")
    vendcat_conformed.show(5, truncate=False)
    write_conformed(vendcat_conformed, "vendcat")
else:
    print("⚠️ No vendcat data available")
```

```python
# ============================================================
# STEP 19 — vendconts
# LFA1 — folder: sap-ecc-raw (root)
# ADRP — folder: srm_ecc_raw_tables
# ============================================================
# lfa1 already read in step 4 — re-use or re-read
lfa1 = safe_read(raw_base, "LFA1")
adrp = safe_read(srm_path, "ADRP")

if lfa1: print("\nLFA1 columns:", lfa1.columns)
if adrp: print("ADRP columns:", adrp.columns)
```

```python
if lfa1:
    lfa1_clean2 = (lfa1
        .filter(F.col("MANDT") == MANDT)
        .dropDuplicates(["LIFNR"])
        .select(
            F.col("LIFNR"),
            F.col("NAME1").alias("supplier_name")
            if "NAME1" in lfa1.columns
            else F.lit(None).cast("string").alias("supplier_name"),
            F.col("TELF1").alias("phone")
            if "TELF1" in lfa1.columns
            else F.lit(None).cast("string").alias("phone"),
            F.col("TELFX").alias("fax")
            if "TELFX" in lfa1.columns
            else F.lit(None).cast("string").alias("fax"),
            F.col("ADRNR").alias("address_number")
            if "ADRNR" in lfa1.columns
            else F.lit(None).cast("string").alias("address_number"),
            F.col("LAND1").alias("country")
            if "LAND1" in lfa1.columns
            else F.lit(None).cast("string").alias("country"),
            F.col("STRAS").alias("street_address")
            if "STRAS" in lfa1.columns
            else F.lit(None).cast("string").alias("street_address"),
            F.col("ORT01").alias("city")
            if "ORT01" in lfa1.columns
            else F.lit(None).cast("string").alias("city"),
            F.col("ANSPK").alias("contact_person")
            if "ANSPK" in lfa1.columns
            else F.lit(None).cast("string").alias("contact_person"),
        )
    )

    vendconts_silver = lfa1_clean2

    if adrp:
        adrp_clean2 = (adrp
            .filter(F.col("MANDT") == MANDT)
            if "MANDT" in adrp.columns else adrp
        )
        adrp_clean2 = (adrp_clean2
            .dropDuplicates(["ADDRNUMBER"])
            .select(
                F.col("ADDRNUMBER").alias("address_number"),
                F.col("SMTP_ADDR").alias("email_address")
                if "SMTP_ADDR" in adrp.columns
                else F.lit(None).cast("string").alias("email_address"),
                F.col("FIRSTNAME").alias("contact_first_name")
                if "FIRSTNAME" in adrp.columns
                else F.lit(None).cast("string").alias("contact_first_name"),
                F.col("LASTNAME").alias("contact_last_name")
                if "LASTNAME" in adrp.columns
                else F.lit(None).cast("string").alias("contact_last_name"),
                F.col("TEL_NUMBER").alias("contact_phone")
                if "TEL_NUMBER" in adrp.columns
                else F.lit(None).cast("string").alias("contact_phone"),
            )
        )
        vendconts_silver = lfa1_clean2.join(adrp_clean2, on="address_number", how="left")

    vendconts_conformed = (vendconts_silver
        .withColumnRenamed("LIFNR", "vendor_code")
        .filter(F.col("vendor_code").isNotNull())
    )
    print(f"vendconts rows: {vendconts_conformed.count():,}")
    vendconts_conformed.show(5, truncate=False)
    write_conformed(vendconts_conformed, "vendconts")
```

```python
# ============================================================
# STEP 20 — vendfin
# LFA1 — folder: sap-ecc-raw (root)
# BSAK — folder: srm_ecc_raw_tables
# ============================================================
bsak = safe_read(srm_path, "BSAK")
if bsak: print("\nBSAK columns:", bsak.columns)
```

```python
if lfa1:
    lfa1_fin = (lfa1
        .filter(F.col("MANDT") == MANDT)
        .dropDuplicates(["LIFNR"])
        .select(
            F.col("LIFNR"),
            F.col("NAME1").alias("supplier_name")
            if "NAME1" in lfa1.columns
            else F.lit(None).cast("string").alias("supplier_name"),
            F.col("STCD1").alias("tax_number")
            if "STCD1" in lfa1.columns
            else F.lit(None).cast("string").alias("tax_number"),
            F.col("STCEG").alias("vat_number")
            if "STCEG" in lfa1.columns
            else F.lit(None).cast("string").alias("vat_number"),
            F.col("LAND1").alias("country")
            if "LAND1" in lfa1.columns
            else F.lit(None).cast("string").alias("country"),
        )
    )

    vendfin_silver = lfa1_fin

    if bsak:
        bsak_clean = (bsak
            .filter(F.col("MANDT") == MANDT)
            if "MANDT" in bsak.columns else bsak
        )
        bsak_clean = (bsak_clean
            .dropDuplicates(["LIFNR","BELNR","GJAHR"])
            .select(
                F.col("LIFNR"),
                F.col("BUKRS").alias("company_code")
                if "BUKRS" in bsak.columns
                else F.lit(None).cast("string").alias("company_code"),
                F.col("BELNR").alias("document_number")
                if "BELNR" in bsak.columns
                else F.lit(None).cast("string").alias("document_number"),
                F.col("GJAHR").alias("fiscal_year")
                if "GJAHR" in bsak.columns
                else F.lit(None).cast("string").alias("fiscal_year"),
                F.col("WRBTR").cast("decimal(18,2)").alias("invoice_amount")
                if "WRBTR" in bsak.columns
                else F.lit(None).cast("decimal(18,2)").alias("invoice_amount"),
                F.col("WAERS").alias("currency")
                if "WAERS" in bsak.columns
                else F.lit(None).cast("string").alias("currency"),
                F.to_date(F.col("BUDAT"), "yyyyMMdd").alias("posting_date")
                if "BUDAT" in bsak.columns
                else F.lit(None).cast("date").alias("posting_date"),
                F.to_date(F.col("AUGDT"), "yyyyMMdd").alias("clearing_date")
                if "AUGDT" in bsak.columns
                else F.lit(None).cast("date").alias("clearing_date"),
            )
        )
        vendfin_silver = lfa1_fin.join(bsak_clean, on="LIFNR", how="left")

    vendfin_conformed = (vendfin_silver
        .withColumnRenamed("LIFNR", "vendor_code")
        .filter(F.col("vendor_code").isNotNull())
    )
    print(f"vendfin rows: {vendfin_conformed.count():,}")
    vendfin_conformed.show(5, truncate=False)
    write_conformed(vendfin_conformed, "vendfin")
```

```python
# ============================================================
# STEP 21 — vendreq
# LFA1 — folder: sap-ecc-raw (root)
# ============================================================
if lfa1:
    vendreq_conformed = (lfa1
        .filter(F.col("MANDT") == MANDT)
        .dropDuplicates(["LIFNR"])
        .select(
            F.col("LIFNR").alias("vendor_code"),
            F.col("NAME1").alias("vendor_name")
            if "NAME1" in lfa1.columns
            else F.lit(None).cast("string").alias("vendor_name"),
            F.col("KTOKK").alias("account_group")
            if "KTOKK" in lfa1.columns
            else F.lit(None).cast("string").alias("account_group"),
            F.col("LAND1").alias("country")
            if "LAND1" in lfa1.columns
            else F.lit(None).cast("string").alias("country"),
            F.col("STRAS").alias("street_address")
            if "STRAS" in lfa1.columns
            else F.lit(None).cast("string").alias("street_address"),
            F.col("ORT01").alias("city")
            if "ORT01" in lfa1.columns
            else F.lit(None).cast("string").alias("city"),
            F.col("TELF1").alias("phone")
            if "TELF1" in lfa1.columns
            else F.lit(None).cast("string").alias("phone"),
            F.col("STCD1").alias("tax_number")
            if "STCD1" in lfa1.columns
            else F.lit(None).cast("string").alias("tax_number"),
            F.when(F.col("SPERR") == "X", "Blocked")
             .otherwise("Active").alias("status")
            if "SPERR" in lfa1.columns
            else F.lit("Active").alias("status"),
            F.to_date(F.col("ERDAT"), "yyyyMMdd").alias("created_date")
            if "ERDAT" in lfa1.columns
            else F.lit(None).cast("date").alias("created_date"),
        )
        .filter(F.col("vendor_code").isNotNull())
    )
    print(f"vendreq rows: {vendreq_conformed.count():,}")
    vendreq_conformed.show(5, truncate=False)
    write_conformed(vendreq_conformed, "vendreq")
```

```python
# ============================================================
# STEP 22 — woitems
# RESB — folder: pm-asset-events
# ============================================================
resb = safe_read(pm_path, "RESB")
if resb: print("\nRESB columns:", resb.columns)
```

```python
if resb:
    woitems_conformed = (resb
        .filter(F.col("MANDT") == MANDT)
        .dropDuplicates(["RSNUM","RSPOS"])
        .select(
            F.col("RSNUM"),
            F.col("RSPOS"),
            F.col("AUFNR").alias("work_order_number")
            if "AUFNR" in resb.columns
            else F.lit(None).cast("string").alias("work_order_number"),
            F.col("MATNR").alias("material_code")
            if "MATNR" in resb.columns
            else F.lit(None).cast("string").alias("material_code"),
            F.col("MAKTX").alias("material_description")
            if "MAKTX" in resb.columns
            else F.lit(None).cast("string").alias("material_description"),
            F.col("BDMNG").cast("decimal(18,3)").alias("required_quantity")
            if "BDMNG" in resb.columns
            else F.lit(None).cast("decimal(18,3)").alias("required_quantity"),
            F.col("MEINS").alias("unit_of_measure")
            if "MEINS" in resb.columns
            else F.lit(None).cast("string").alias("unit_of_measure"),
            F.col("LGORT").alias("storage_location")
            if "LGORT" in resb.columns
            else F.lit(None).cast("string").alias("storage_location"),
            F.col("WERKS").alias("plant")
            if "WERKS" in resb.columns
            else F.lit(None).cast("string").alias("plant"),
            F.col("KZEAR").alias("final_issue_indicator")
            if "KZEAR" in resb.columns
            else F.lit(None).cast("string").alias("final_issue_indicator"),
            F.col("KOSTL").alias("cost_centre")
            if "KOSTL" in resb.columns
            else F.lit(None).cast("string").alias("cost_centre"),
            F.to_date(F.col("BDTER"), "yyyyMMdd").alias("requirement_date")
            if "BDTER" in resb.columns
            else F.lit(None).cast("date").alias("requirement_date"),
        )
        .withColumnRenamed("RSNUM", "reservation_number")
        .withColumnRenamed("RSPOS", "reservation_item")
        .filter(F.col("reservation_number").isNotNull())
    )
    print(f"woitems rows: {woitems_conformed.count():,}")
    woitems_conformed.show(5, truncate=False)
    write_conformed(woitems_conformed, "woitems")
```

```python
# ============================================================
# STEP 23 — transacts
# VBAK — folder: srm_ecc_raw_tables
# VBAP — folder: srm_ecc_raw_tables
# VBEP — folder: srm_ecc_raw_tables
# VBRK — folder: sap-ecc-raw (root)
# VBRP — folder: sap-ecc-raw (root)
# ============================================================
vbak = safe_read(srm_path, "VBAK")
vbap = safe_read(srm_path, "VBAP")
vbep = safe_read(srm_path, "VBEP")
vbrk = safe_read(raw_base,  "VBRK")
vbrp = safe_read(raw_base,  "VBRP")

if vbak: print("\nVBAK columns:", vbak.columns)
if vbap: print("VBAP columns:", vbap.columns)
if vbep: print("VBEP columns:", vbep.columns)
if vbrk: print("VBRK columns:", vbrk.columns)
if vbrp: print("VBRP columns:", vbrp.columns)
```

```python
if vbrk:
    vbrk_clean = (vbrk
        .filter(F.col("MANDT") == MANDT)
        .dropDuplicates(["VBELN"])
        .select(
            F.col("VBELN"),
            F.col("FKART").alias("billing_type")
            if "FKART" in vbrk.columns
            else F.lit(None).cast("string").alias("billing_type"),
            F.to_date(F.col("FKDAT"), "yyyyMMdd").alias("billing_date")
            if "FKDAT" in vbrk.columns
            else F.lit(None).cast("date").alias("billing_date"),
            F.col("KUNAG").alias("sold_to_party")
            if "KUNAG" in vbrk.columns
            else F.lit(None).cast("string").alias("sold_to_party"),
            F.col("NETWR").cast("decimal(18,2)").alias("net_value")
            if "NETWR" in vbrk.columns
            else F.lit(None).cast("decimal(18,2)").alias("net_value"),
            F.col("WAERK").alias("currency")
            if "WAERK" in vbrk.columns
            else F.lit(None).cast("string").alias("currency"),
            F.col("VKORG").alias("sales_org")
            if "VKORG" in vbrk.columns
            else F.lit(None).cast("string").alias("sales_org"),
            F.col("RFBSK").alias("payment_status")
            if "RFBSK" in vbrk.columns
            else F.lit(None).cast("string").alias("payment_status"),
        )
    )

    transacts_silver = vbrk_clean

    # Join VBRP — billing line items
    if vbrp:
        vbrp_clean = (vbrp
            .filter(F.col("MANDT") == MANDT)
            .dropDuplicates(["VBELN","POSNR"])
            .select(
                F.col("VBELN"),
                F.col("POSNR").alias("billing_item"),
                F.col("MATNR").alias("material_code")
                if "MATNR" in vbrp.columns
                else F.lit(None).cast("string").alias("material_code"),
                F.col("ARKTX").alias("item_description")
                if "ARKTX" in vbrp.columns
                else F.lit(None).cast("string").alias("item_description"),
                F.col("FKIMG").cast("decimal(18,3)").alias("billed_quantity")
                if "FKIMG" in vbrp.columns
                else F.lit(None).cast("decimal(18,3)").alias("billed_quantity"),
                F.col("NETWR").cast("decimal(18,2)").alias("line_net_value")
                if "NETWR" in vbrp.columns
                else F.lit(None).cast("decimal(18,2)").alias("line_net_value"),
                F.col("WERKS").alias("plant")
                if "WERKS" in vbrp.columns
                else F.lit(None).cast("string").alias("plant"),
            )
        )
        transacts_silver = transacts_silver.join(vbrp_clean, on="VBELN", how="left")

    # Join VBAK — sales order header
    if vbak:
        vbak_clean = (vbak
            .filter(F.col("MANDT") == MANDT)
            .dropDuplicates(["VBELN"])
            .select(
                F.col("VBELN").alias("sales_order_number"),
                F.col("AUART").alias("sales_order_type")
                if "AUART" in vbak.columns
                else F.lit(None).cast("string").alias("sales_order_type"),
                F.col("KUNNR").alias("customer_code")
                if "KUNNR" in vbak.columns
                else F.lit(None).cast("string").alias("customer_code"),
            )
        )
        # Note: VBAK joins via reference in VBRP (AUBEL)
        if "AUBEL" in vbrp_clean.columns:
            transacts_silver = transacts_silver.join(
                vbak_clean,
                transacts_silver["AUBEL"] == vbak_clean["sales_order_number"],
                how="left"
            )

    transacts_conformed = (transacts_silver
        .withColumnRenamed("VBELN", "transaction_id")
        .filter(F.col("transaction_id").isNotNull())
    )
    print(f"transacts rows: {transacts_conformed.count():,}")
    transacts_conformed.show(5, truncate=False)
    write_conformed(transacts_conformed, "transacts")
else:
    print("⚠️ VBRK not available — transacts skipped")
```

```python
# ============================================================
# STEP 24 — transfers
# MKPF           — folder: transaction-data
# MSEG           — folder: transaction-data
# DAC_D_MATDOC   — folder: srm_ecc_raw_tables
# ============================================================
mkpf         = safe_read(tx_path,  "MKPF")
mseg         = safe_read(tx_path,  "MSEG")
dac_d_matdoc = safe_read(srm_path, "DAC_D_MATDOC")

if mkpf:         print("\nMKPF         columns:", mkpf.columns)
if mseg:         print("MSEG         columns:", mseg.columns)
if dac_d_matdoc: print("DAC_D_MATDOC columns:", dac_d_matdoc.columns)
```

```python
if mkpf and mseg:
    mkpf_clean2 = (mkpf
        .filter(F.col("MANDT") == MANDT)
        .dropDuplicates(["MBLNR","MJAHR"])
        .select(
            F.col("MBLNR"),
            F.col("MJAHR"),
            F.to_date(F.col("BUDAT"), "yyyyMMdd").alias("posting_date")
            if "BUDAT" in mkpf.columns
            else F.lit(None).cast("date").alias("posting_date"),
            F.col("USNAM").alias("created_by")
            if "USNAM" in mkpf.columns
            else F.lit(None).cast("string").alias("created_by"),
            F.col("BLART").alias("document_type")
            if "BLART" in mkpf.columns
            else F.lit(None).cast("string").alias("document_type"),
        )
    )

    # Filter MSEG to transfer movements only (301, 303, 305, 311, 313, 315)
    transfer_types = ["301","303","305","311","313","315","351","352"]
    mseg_transfers = (mseg
        .filter(F.col("MANDT") == MANDT)
        .filter(F.col("BWART").isin(transfer_types)
                if "BWART" in mseg.columns else F.lit(True))
        .dropDuplicates(["MBLNR","MJAHR","ZEILE"])
        .select(
            F.col("MBLNR"),
            F.col("MJAHR"),
            F.col("ZEILE").alias("document_item"),
            F.col("MATNR").alias("material_code"),
            F.col("WERKS").alias("from_plant"),
            F.col("LGORT").alias("from_storage_location")
            if "LGORT" in mseg.columns
            else F.lit(None).cast("string").alias("from_storage_location"),
            F.col("UMWRK").alias("to_plant")
            if "UMWRK" in mseg.columns
            else F.lit(None).cast("string").alias("to_plant"),
            F.col("UMLGO").alias("to_storage_location")
            if "UMLGO" in mseg.columns
            else F.lit(None).cast("string").alias("to_storage_location"),
            F.col("BWART").alias("movement_type")
            if "BWART" in mseg.columns
            else F.lit(None).cast("string").alias("movement_type"),
            F.col("MENGE").cast("decimal(18,3)").alias("transfer_quantity")
            if "MENGE" in mseg.columns
            else F.lit(None).cast("decimal(18,3)").alias("transfer_quantity"),
            F.col("MEINS").alias("unit_of_measure")
            if "MEINS" in mseg.columns
            else F.lit(None).cast("string").alias("unit_of_measure"),
            F.col("DMBTR").cast("decimal(18,2)").alias("transfer_value")
            if "DMBTR" in mseg.columns
            else F.lit(None).cast("decimal(18,2)").alias("transfer_value"),
        )
    )

    transfers_silver = mseg_transfers.join(mkpf_clean2, on=["MBLNR","MJAHR"], how="left")

    # Enrich with DAC_D_MATDOC if available
    if dac_d_matdoc:
        print(f"DAC_D_MATDOC rows: {dac_d_matdoc.count():,}")
        dac_key = next((c for c in ["MBLNR","MATDOC"] if c in dac_d_matdoc.columns), None)
        if dac_key:
            dac_clean = (dac_d_matdoc
                .filter(F.col("MANDT") == MANDT)
                if "MANDT" in dac_d_matdoc.columns else dac_d_matdoc
            )
            dac_clean = (dac_clean
                .dropDuplicates([dac_key])
                .select(
                    F.col(dac_key).alias("MBLNR"),
                    *[F.col(c) for c in dac_clean.columns
                      if c not in [dac_key,"MANDT","__timestamp",
                                   "__operation_type","__sequence_number"]]
                )
            )
            transfers_silver = transfers_silver.join(
                dac_clean, on="MBLNR", how="left"
            )

    transfers_conformed = (transfers_silver
        .withColumnRenamed("MBLNR", "transfer_document_number")
        .withColumnRenamed("MJAHR", "document_year")
        .filter(F.col("transfer_document_number").isNotNull())
    )
    print(f"transfers rows: {transfers_conformed.count():,}")
    transfers_conformed.show(5, truncate=False)
    write_conformed(transfers_conformed, "transfers")
```

```python
# ============================================================
# FINAL CELL — Print all column dtypes for ASA SQL development
# ============================================================
all_tables = {
    "actdetails"      : actdetails_conformed,
    "actlog"          : actlog_conformed,
    "clients"         : clients_conformed,
    "docsup"          : docsup_conformed,
    "itemcat"         : itemcat_conformed,
    "items"           : items_conformed,
    "locations"       : locations_conformed,
    "nations"         : nations_conformed,
    "newdepts"        : newdepts_conformed,
    "newstock"        : newstock_conformed,
    "pendingpos"      : pendingpos_conformed,
    "pendingrequests" : pendingrequests_conformed,
    "settings"        : settings_conformed,
    "stowners"        : stowners_conformed,
    "stowner2"        : stowner2_conformed,
    "vendacct"        : vendacct_conformed,
    "vendapps"        : vendapps_conformed,
    "vendcat"         : vendcat_conformed,
    "vendconts"       : vendconts_conformed,
    "vendfin"         : vendfin_conformed,
    "vendreq"         : vendreq_conformed,
    "woitems"         : woitems_conformed,
    "transacts"       : transacts_conformed,
    "transfers"       : transfers_conformed,
}

def to_asa(spark_type):
    t = spark_type.lower()
    if t == "string":    return "NVARCHAR(255)"
    if t == "date":      return "DATE"
    if t == "timestamp": return "DATETIME2"
    if t in ("integer","int"): return "INT"
    if t == "long":      return "BIGINT"
    if t in ("double","float"): return "DECIMAL(18,4)"
    if "decimal" in t:   return t.upper().replace("DECIMALTYPE(","DECIMAL(").replace(")",")")
    if t == "boolean":   return "NVARCHAR(5)"
    return "NVARCHAR(255)"

for tname, df in all_tables.items():
    try:
        print(f"\n-- ============================================================")
        print(f"-- {tname}")
        print(f"-- ============================================================")
        print(f"-- Rows: {df.count():,}  |  Columns: {len(df.dtypes)}")
        print(f"CREATE TABLE [zzSTG_offshore_srm].[{tname}]")
        print("(")
        for i,(col,typ) in enumerate(df.dtypes):
            asa = to_asa(typ)
            comma = "," if i < len(df.dtypes)-1 else ""
            print(f"    [{col}]{' ' * max(1,42-len(col))}{asa:<25} NULL{comma}")
        print(")")
        print("WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);")
    except Exception as e:
        print(f"\n-- ⚠️ {tname} not available: {e}")
```