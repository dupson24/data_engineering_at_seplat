```python
# ============================================================
# SunSystems — Bronze → Silver → Conformed
# SAP ECC source tables → offshore_sunsystems schema
# ============================================================

raw_base        = "/mnt/sap-ecc-datasphere/sap-ecc-raw"
co_path         = f"{raw_base}/co-budget"
master_path     = f"{raw_base}/master-data"
pm_path         = f"{raw_base}/pm-asset-events"
ref_path        = f"{raw_base}/reference-and-config"
hr_path         = f"{raw_base}/hr"
tx_path         = f"{raw_base}/transaction-data"
eam_path        = f"{raw_base}/eam_ecc_raw_tables"
srm_path        = f"{raw_base}/srm_ecc_raw_tables"
raw_base_root   = raw_base  # sap-ecc-raw root for LFA1/LFBK/ADRC/VBRK

conformed_path  = "/mnt/sap-ecc-datasphere/sap-ecc-conformed/sunsystems"
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
    print(f"✅ {target_name}: {df.count():,} rows written")

# Columns to always exclude (SunSystems SCD/hash cols not needed in conformed)
SS_EXCLUDE = {"Sk_Id", "Latest_Indicator", "Hash", "__timestamp",
              "__operation_type", "__sequence_number"}

def ss_select(df, key_col, rename_as=None, extra_excludes=None):
    """Select all columns from SunSystems table except SCD/hash cols."""
    exclude = SS_EXCLUDE | (extra_excludes or set())
    cols = [c for c in df.columns if c not in exclude]
    df2 = df.dropDuplicates([key_col]).select(*[F.col(c) for c in cols])
    if rename_as:
        df2 = df2.withColumnRenamed(key_col, rename_as)
    return df2
```

```python
# ============================================================
# STEP 1 — Analysis_Code_Extensions
# SAP source: COEP + COSS + COSP — folder: co-budget
# Target: SunSystems Analysis_Code_Extensions schema (29 cols)
# ============================================================
coep = safe_read(co_path, "COEP")
coss = safe_read(co_path, "COSS")
cosp = safe_read(co_path, "COSP")

if coep: print("\nCOEP columns:", coep.columns)
if coss: print("COSS columns:", coss.columns)
if cosp: print("COSP columns:", cosp.columns)
```

```python
# Analysis_Code_Extensions — target schema has 29 columns
# Build from CO source tables mapping to SunSystems column names
if coep or coss or cosp:
    base_df = None

    if coss:
        coss_clean = (coss
            .filter(F.col("MANDT") == MANDT)
            .dropDuplicates(["KOKRS","KOSTL","GJAHR"])
            .select(
                F.col("KOKRS").alias("Business_Unit"),
                F.col("KOSTL").alias("Analysis_Code"),
                F.lit("1").alias("Analysis_Dimension_Id"),
                F.col("AEDAT").alias("DateTime_Last_Updated")
                if "AEDAT" in coss.columns
                else F.lit(None).cast("string").alias("DateTime_Last_Updated"),
                F.col("AENAM").alias("User_Id_Last_Updated")
                if "AENAM" in coss.columns
                else F.lit(None).cast("string").alias("User_Id_Last_Updated"),
                # Extension fields — map from custom Z-fields if present
                *[F.lit(None).cast("string").alias(f"Extension_Fixed_{i}")
                  for i in range(1, 11)],
                *[F.lit(None).cast("string").alias(f"Extension_Text_{i}")
                  for i in range(6, 10)],
                F.lit(None).cast("string").alias("User_Defined_Fields"),
                F.lit(None).cast("string").alias("Valid_From"),
                F.lit(None).cast("string").alias("Valid_Until"),
                F.lit(None).cast("string").alias("Created"),
                F.lit(None).cast("string").alias("Created_By"),
                F.lit(None).cast("string").alias("Last_Updated"),
                F.lit(None).cast("string").alias("Last_Updated_By"),
            )
        )
        base_df = coss_clean

    if base_df is None and coep:
        # Fall back to COEP if COSS empty
        base_df = (coep
            .filter(F.col("MANDT") == MANDT)
            .dropDuplicates(["KOKRS","KOSTL","GJAHR"])
            .select(
                F.col("KOKRS").alias("Business_Unit"),
                F.col("KOSTL").alias("Analysis_Code"),
                F.lit("1").alias("Analysis_Dimension_Id"),
                F.col("AEDAT").alias("DateTime_Last_Updated")
                if "AEDAT" in coep.columns
                else F.lit(None).cast("string").alias("DateTime_Last_Updated"),
                F.col("AENAM").alias("User_Id_Last_Updated")
                if "AENAM" in coep.columns
                else F.lit(None).cast("string").alias("User_Id_Last_Updated"),
                *[F.lit(None).cast("string").alias(f"Extension_Fixed_{i}")
                  for i in range(1, 11)],
                *[F.lit(None).cast("string").alias(f"Extension_Text_{i}")
                  for i in range(6, 10)],
                F.lit(None).cast("string").alias("User_Defined_Fields"),
                F.lit(None).cast("string").alias("Valid_From"),
                F.lit(None).cast("string").alias("Valid_Until"),
                F.lit(None).cast("string").alias("Created"),
                F.lit(None).cast("string").alias("Created_By"),
                F.lit(None).cast("string").alias("Last_Updated"),
                F.lit(None).cast("string").alias("Last_Updated_By"),
            )
        )

    if base_df:
        print(f"Analysis_Code_Extensions rows: {base_df.count():,}")
        base_df.show(3, truncate=False)
        write_conformed(base_df, "Analysis_Code_Extensions")
    else:
        print("⚠️ No CO source data available for Analysis_Code_Extensions")
```

```python
# ============================================================
# STEP 2 — Analysis_Codes
# SAP: CSKS (master-data) + AUFK (pm-asset-events) + PRPS (master-data)
# Target: 30 SunSystems columns
# ============================================================
csks = safe_read(master_path, "CSKS")
aufk = safe_read(pm_path,     "AUFK")
prps = safe_read(master_path, "PRPS")

if csks: print("\nCSKS columns:", csks.columns)
if aufk: print("AUFK columns:", aufk.columns)
if prps: print("PRPS columns:", prps.columns)
```

```python
def build_analysis_code_row(df, key_col, dim_id, src_name):
    """Map any CO object to Analysis_Codes target schema."""
    mandt_col = "MANDT" if "MANDT" in df.columns else None
    df2 = df.filter(F.col("MANDT") == MANDT) if mandt_col else df

    # Detect available columns dynamically
    kokrs = "KOKRS" if "KOKRS" in df.columns else None
    aedat = "AEDAT" if "AEDAT" in df.columns else None
    aenam = "AENAM" if "AENAM" in df.columns else None
    ltext = next((c for c in ["LTEXT","KTEXT","POST1"] if c in df.columns), None)
    sperrz= "SPERRZ" if "SPERRZ" in df.columns else None
    stat  = "BUKRS" if "BUKRS" in df.columns else None  # use BUKRS as status proxy

    return (df2
        .dropDuplicates([key_col])
        .select(
            F.col(kokrs).alias("Business_Unit")
            if kokrs else F.lit(None).cast("string").alias("Business_Unit"),
            F.col(key_col).alias("Analysis_Code"),
            F.lit(dim_id).alias("Analysis_Dimension_Id"),
            F.lit(None).cast("string").alias("Budget_Checking_Code"),
            F.lit(None).cast("string").alias("Budget_Checking_Description"),
            F.lit(None).cast("string").alias("Budget_Navigation_Method_Code"),
            F.lit(None).cast("string").alias("Budget_Navigation_Method_Description"),
            F.lit(None).cast("string").alias("Budget_Stop_Code"),
            F.lit(None).cast("string").alias("Budget_Stop_Description"),
            F.lit(None).cast("string").alias("Combined_Budget_Check_Code"),
            F.lit(None).cast("string").alias("Combined_Budget_Check_Description"),
            F.col(aedat).alias("DateTime_Last_Updated")
            if aedat else F.lit(None).cast("string").alias("DateTime_Last_Updated"),
            F.lit(None).cast("string").alias("Lookup_Code"),
            F.col(ltext).alias("Name")
            if ltext else F.lit(None).cast("string").alias("Name"),
            F.col(sperrz).alias("Prohibit_Posting_Code")
            if sperrz else F.lit(None).cast("string").alias("Prohibit_Posting_Code"),
            F.lit(None).cast("string").alias("Prohibit_Posting_Description"),
            F.lit("A").alias("Status_Code"),
            F.lit("Active").alias("Status_Description"),
            F.col(aenam).alias("User_Id_Last_Updated")
            if aenam else F.lit(None).cast("string").alias("User_Id_Last_Updated"),
            F.lit(None).cast("string").alias("User_Defined_Fields"),
            F.lit(None).cast("string").alias("Valid_From"),
            F.lit(None).cast("string").alias("Valid_Until"),
            F.lit(None).cast("string").alias("Created"),
            F.lit(None).cast("string").alias("Created_By"),
            F.lit(None).cast("string").alias("Last_Updated"),
            F.lit(None).cast("string").alias("Last_Updated_By"),
            F.lit(src_name).alias("_source_table"),
        )
    )

ac_dfs = []
if csks:
    ac_dfs.append(build_analysis_code_row(csks, "KOSTL", "COST_CENTRE", "CSKS"))
if aufk:
    ac_dfs.append(build_analysis_code_row(aufk, "AUFNR", "INT_ORDER",   "AUFK"))
if prps:
    ac_dfs.append(build_analysis_code_row(prps, "PSPNR", "WBS_ELEMENT", "PRPS"))

if ac_dfs:
    from functools import reduce
    analysis_codes_conformed = reduce(
        lambda a, b: a.unionByName(b, allowMissingColumns=True), ac_dfs
    )
    analysis_codes_conformed = analysis_codes_conformed.filter(
        F.col("Analysis_Code").isNotNull()
    )
    print(f"Analysis_Codes rows: {analysis_codes_conformed.count():,}")
    analysis_codes_conformed.show(3, truncate=False)
    write_conformed(analysis_codes_conformed, "Analysis_Codes")
```

```python
# ============================================================
# STEP 3 — Analysis_Dimension_Names
# SAP: TKA01 + CSKA — folder: master-data
# Target: 27 SunSystems columns
# ============================================================
tka01 = safe_read(master_path, "TKA01")
cska  = safe_read(master_path, "CSKA")

if tka01: print("\nTKA01 columns:", tka01.columns)
if cska:  print("CSKA  columns:", cska.columns)
```

```python
if tka01:
    tka01_clean = (tka01
        .filter(F.col("MANDT") == MANDT)
        if "MANDT" in tka01.columns else tka01
    )
    tka01_clean = (tka01_clean
        .dropDuplicates(["KOKRS"])
        .select(
            F.col("KOKRS").alias("Business_Unit"),
            F.lit("1").alias("Analysis_Dimension_Id"),
            F.lit(None).cast("string").alias("Amend_In_Account_Allocation_Code"),
            F.lit(None).cast("string").alias("Amend_In_Account_Allocation_Description"),
            F.col("BEZEI").alias("Description")
            if "BEZEI" in tka01.columns
            else F.lit(None).cast("string").alias("Description"),
            F.col("AEDAT").alias("DateTime_Last_Updated")
            if "AEDAT" in tka01.columns
            else F.lit(None).cast("string").alias("DateTime_Last_Updated"),
            F.lit(10).cast("int").alias("Length"),
            F.lit(None).cast("string").alias("Linked_Code"),
            F.lit(None).cast("string").alias("Linked_Description"),
            F.lit(None).cast("string").alias("Look_Up_Code"),
            F.lit(None).cast("string").alias("shortHeading"),
            F.lit("A").alias("Status_Code"),
            F.lit("Active").alias("Status_Description"),
            F.lit(None).cast("string").alias("Validation_Method_Code"),
            F.lit(None).cast("string").alias("Validation_Method_Description"),
            F.col("AENAM").alias("User_Id_Last_Updated")
            if "AENAM" in tka01.columns
            else F.lit(None).cast("string").alias("User_Id_Last_Updated"),
            F.lit(None).cast("string").alias("User_Defined_Fields"),
            F.lit(None).cast("string").alias("Valid_From"),
            F.lit(None).cast("string").alias("Valid_Until"),
            F.lit(None).cast("string").alias("Created"),
            F.lit(None).cast("string").alias("Created_By"),
            F.lit(None).cast("string").alias("Last_Updated"),
            F.lit(None).cast("string").alias("Last_Updated_By"),
        )
    )

    # Enrich with CSKA — cost element dimension details
    if cska:
        cska_clean = (cska
            .filter(F.col("MANDT") == MANDT)
            if "MANDT" in cska.columns else cska
        )
        cska_clean = (cska_clean
            .dropDuplicates(["KOKRS","KSTAR"])
            .select(
                F.col("KOKRS").alias("Business_Unit"),
                F.lit("COST_ELEMENT").alias("Analysis_Dimension_Id"),
                F.lit(None).cast("string").alias("Amend_In_Account_Allocation_Code"),
                F.lit(None).cast("string").alias("Amend_In_Account_Allocation_Description"),
                F.lit(None).cast("string").alias("Description"),
                F.col("AEDAT").alias("DateTime_Last_Updated")
                if "AEDAT" in cska.columns
                else F.lit(None).cast("string").alias("DateTime_Last_Updated"),
                F.lit(10).cast("int").alias("Length"),
                F.lit(None).cast("string").alias("Linked_Code"),
                F.lit(None).cast("string").alias("Linked_Description"),
                F.lit(None).cast("string").alias("Look_Up_Code"),
                F.lit(None).cast("string").alias("shortHeading"),
                F.lit("A").alias("Status_Code"),
                F.lit("Active").alias("Status_Description"),
                F.lit(None).cast("string").alias("Validation_Method_Code"),
                F.lit(None).cast("string").alias("Validation_Method_Description"),
                F.col("AENAM").alias("User_Id_Last_Updated")
                if "AENAM" in cska.columns
                else F.lit(None).cast("string").alias("User_Id_Last_Updated"),
                F.lit(None).cast("string").alias("User_Defined_Fields"),
                F.lit(None).cast("string").alias("Valid_From"),
                F.lit(None).cast("string").alias("Valid_Until"),
                F.lit(None).cast("string").alias("Created"),
                F.lit(None).cast("string").alias("Created_By"),
                F.lit(None).cast("string").alias("Last_Updated"),
                F.lit(None).cast("string").alias("Last_Updated_By"),
            )
        )
        from functools import reduce
        adim_conformed = tka01_clean.unionByName(cska_clean)
    else:
        adim_conformed = tka01_clean

    adim_conformed = adim_conformed.filter(F.col("Business_Unit").isNotNull())
    print(f"Analysis_Dimension_Names rows: {adim_conformed.count():,}")
    adim_conformed.show(3, truncate=False)
    write_conformed(adim_conformed, "Analysis_Dimension_Names")
```

```python
# ============================================================
# STEP 4 — Analysis_Structures
# SAP: SETHEADER (ref-and-config) + SETLEAF (ref-and-config)
#      + CSKT (master-data)
# Target: 20 SunSystems columns
# ============================================================
setheader = safe_read(ref_path,    "SETHEADER")
setleaf   = safe_read(ref_path,    "SETLEAF")
cskt      = safe_read(master_path, "CSKT")

if setheader: print("\nSETHEADER columns:", setheader.columns)
if setleaf:   print("SETLEAF   columns:", setleaf.columns)
if cskt:      print("CSKT      columns:", cskt.columns)
```

```python
astruct_dfs = []

if setheader:
    sh_clean = (setheader
        .filter(F.col("MANDT") == MANDT)
        if "MANDT" in setheader.columns else setheader
    )
    sh_clean = (sh_clean
        .dropDuplicates(["SETNAME","KOKRS"])
        .select(
            F.col("KOKRS").alias("Business_Unit")
            if "KOKRS" in setheader.columns
            else F.lit(None).cast("string").alias("Business_Unit"),
            F.lit("1").alias("Analysis_Dimension_Id"),
            F.col("SETNAME").alias("Analysis_Entity_Id"),
            F.col("AEDAT").alias("DateTime_Last_Updated")
            if "AEDAT" in setheader.columns
            else F.lit(None).cast("string").alias("DateTime_Last_Updated"),
            F.lit(1).cast("int").alias("Entry_Number"),
            F.col("SETNAME").alias("Short_Heading"),
            F.col("AENAM").alias("User_Id_Last_Updated")
            if "AENAM" in setheader.columns
            else F.lit(None).cast("string").alias("User_Id_Last_Updated"),
            F.col("SETNAME").alias("Code"),
            F.col("DESCRIPT").alias("Description")
            if "DESCRIPT" in setheader.columns
            else F.lit(None).cast("string").alias("Description"),
            F.lit(None).cast("string").alias("User_Defined_Fields"),
            F.lit(None).cast("string").alias("Valid_From"),
            F.lit(None).cast("string").alias("Valid_Until"),
            F.lit(None).cast("string").alias("Created"),
            F.lit(None).cast("string").alias("Created_By"),
            F.lit(None).cast("string").alias("Last_Updated"),
            F.lit(None).cast("string").alias("Last_Updated_By"),
        )
    )
    astruct_dfs.append(sh_clean)

if cskt:
    cskt_clean = (cskt
        .filter(F.col("MANDT") == MANDT)
        if "MANDT" in cskt.columns else cskt
    )
    cskt_clean = (cskt_clean
        .filter(F.col("SPRAS") == "EN"
                if "SPRAS" in cskt.columns else F.lit(True))
        .dropDuplicates(["KOKRS","KOSTL"])
        .select(
            F.col("KOKRS").alias("Business_Unit"),
            F.lit("COST_CENTRE").alias("Analysis_Dimension_Id"),
            F.col("KOSTL").alias("Analysis_Entity_Id"),
            F.col("AEDAT").alias("DateTime_Last_Updated")
            if "AEDAT" in cskt.columns
            else F.lit(None).cast("string").alias("DateTime_Last_Updated"),
            F.lit(1).cast("int").alias("Entry_Number"),
            F.col("KTEXT").alias("Short_Heading")
            if "KTEXT" in cskt.columns
            else F.lit(None).cast("string").alias("Short_Heading"),
            F.col("AENAM").alias("User_Id_Last_Updated")
            if "AENAM" in cskt.columns
            else F.lit(None).cast("string").alias("User_Id_Last_Updated"),
            F.col("KOSTL").alias("Code"),
            F.col("LTEXT").alias("Description")
            if "LTEXT" in cskt.columns
            else F.lit(None).cast("string").alias("Description"),
            F.lit(None).cast("string").alias("User_Defined_Fields"),
            F.lit(None).cast("string").alias("Valid_From"),
            F.lit(None).cast("string").alias("Valid_Until"),
            F.lit(None).cast("string").alias("Created"),
            F.lit(None).cast("string").alias("Created_By"),
            F.lit(None).cast("string").alias("Last_Updated"),
            F.lit(None).cast("string").alias("Last_Updated_By"),
        )
    )
    astruct_dfs.append(cskt_clean)

if astruct_dfs:
    from functools import reduce
    astruct_conformed = reduce(
        lambda a, b: a.unionByName(b, allowMissingColumns=True), astruct_dfs
    )
    astruct_conformed = astruct_conformed.filter(
        F.col("Analysis_Entity_Id").isNotNull()
    )
    print(f"Analysis_Structures rows: {astruct_conformed.count():,}")
    astruct_conformed.show(3, truncate=False)
    write_conformed(astruct_conformed, "Analysis_Structures")
```

```python
# ============================================================
# STEP 5 — Analysis_Sub_Dimensions
# SAP: CSKA (Cost Elements by Controlling Area) — co-budget
# Target: 21 SunSystems columns
# ============================================================
cska = safe_read(co_path, "CSKA")
if cska: print("\nCOBUDGET CSKA columns:", cska.columns)
```

```python
if cska:
    cska_sub = (cska
        .filter(F.col("MANDT") == MANDT)
        if "MANDT" in cska.columns else cska
    )
    cska_sub = (cska_sub
        .dropDuplicates(["KOKRS","KSTAR"])
        .select(
            F.col("KOKRS").alias("Business_Unit"),
            F.lit("COST_ELEMENT").alias("Analysis_Dimension_Id"),
            F.col("KSTAR").alias("Analysis_Subdimension_Code"),
            F.col("AEDAT").alias("DateTimeLast_Updated")
            if "AEDAT" in cska.columns
            else F.lit(None).cast("string").alias("DateTimeLast_Updated"),
            F.col("LTEXT").alias("Description")
            if "LTEXT" in cska.columns
            else F.lit(None).cast("string").alias("Description"),
            F.lit(None).cast("string").alias("Mask"),
            F.col("KTEXT").alias("Short_Heading")
            if "KTEXT" in cska.columns
            else F.lit(None).cast("string").alias("Short_Heading"),
            F.lit("A").alias("Status_Code"),
            F.lit("Active").alias("Status_Description"),
            F.col("AENAM").alias("UserId_Last_Updated")
            if "AENAM" in cska.columns
            else F.lit(None).cast("string").alias("UserId_Last_Updated"),
            F.lit(None).cast("string").alias("User_Defined_Fields"),
            F.lit(None).cast("string").alias("Valid_From"),
            F.lit(None).cast("string").alias("Valid_Until"),
            F.lit(None).cast("string").alias("Created"),
            F.lit(None).cast("string").alias("Created_By"),
            F.lit(None).cast("string").alias("Last_Updated"),
            F.lit(None).cast("string").alias("Last_Updated_By"),
        )
        .filter(F.col("Analysis_Subdimension_Code").isNotNull())
    )

    print(f"Analysis_Sub_Dimensions rows: {cska_sub.count():,}")
    cska_sub.show(3, truncate=False)
    write_conformed(cska_sub, "Analysis_Sub_Dimensions")
```

```python
# ============================================================
# STEP 6 — Budget_Definitions
# SAP: BPGE + BPJA + OKOB — folder: co-budget
# Target: 22 SunSystems columns
# ============================================================
bpge = safe_read(co_path, "BPGE")
bpja = safe_read(co_path, "BPJA")
okob = safe_read(co_path, "OKOB")

if bpge: print("\nBPGE columns:", bpge.columns)
if bpja: print("BPJA columns:", bpja.columns)
if okob: print("OKOB columns:", okob.columns)
```

```python
buddef_dfs = []

if okob:
    okob_clean = (okob
        .filter(F.col("MANDT") == MANDT)
        if "MANDT" in okob.columns else okob
    )
    okob_clean = (okob_clean
        .dropDuplicates(["BUDPRF","KOKRS"])
        .select(
            F.col("KOKRS").alias("Business_Unit")
            if "KOKRS" in okob.columns
            else F.lit(None).cast("string").alias("Business_Unit"),
            F.col("BUDPRF").alias("Budget_Code"),
            F.col("BUDPRF").alias("Budget_Code_Description"),
            F.col("AEDAT").alias("DateTime_Last_Updated")
            if "AEDAT" in okob.columns
            else F.lit(None).cast("string").alias("DateTime_Last_Updated"),
            F.col("LTEXT").alias("Description")
            if "LTEXT" in okob.columns
            else F.lit(None).cast("string").alias("Description"),
            F.lit(None).cast("string").alias("Lookup_Code"),
            F.lit(None).cast("string").alias("Provisional_Posting_Code"),
            F.lit(None).cast("string").alias("Provisional_Posting_Description"),
            F.lit("A").alias("Status_Code"),
            F.lit("Active").alias("Status_Description"),
            F.col("AENAM").alias("User_Id_Last_Updated")
            if "AENAM" in okob.columns
            else F.lit(None).cast("string").alias("User_Id_Last_Updated"),
            F.lit(None).cast("string").alias("User_Defined_Fields"),
            F.lit(None).cast("string").alias("Valid_From"),
            F.lit(None).cast("string").alias("Valid_Until"),
            F.lit(None).cast("string").alias("Created"),
            F.lit(None).cast("string").alias("Created_By"),
            F.lit(None).cast("string").alias("Last_Updated"),
            F.lit(None).cast("string").alias("Last_Updated_By"),
        )
    )
    buddef_dfs.append(okob_clean)

if bpge:
    bpge_clean = (bpge
        .filter(F.col("MANDT") == MANDT)
        if "MANDT" in bpge.columns else bpge
    )
    key_col = next((c for c in ["BUDPRF","VERSN","KOKRS"] if c in bpge.columns), None)
    if key_col:
        bpge_clean = (bpge_clean
            .dropDuplicates([key_col])
            .select(
                F.col("KOKRS").alias("Business_Unit")
                if "KOKRS" in bpge.columns
                else F.lit(None).cast("string").alias("Business_Unit"),
                F.col(key_col).alias("Budget_Code"),
                F.col(key_col).alias("Budget_Code_Description"),
                F.col("AEDAT").alias("DateTime_Last_Updated")
                if "AEDAT" in bpge.columns
                else F.lit(None).cast("string").alias("DateTime_Last_Updated"),
                F.lit(None).cast("string").alias("Description"),
                F.lit(None).cast("string").alias("Lookup_Code"),
                F.lit(None).cast("string").alias("Provisional_Posting_Code"),
                F.lit(None).cast("string").alias("Provisional_Posting_Description"),
                F.lit("A").alias("Status_Code"),
                F.lit("Active").alias("Status_Description"),
                F.col("AENAM").alias("User_Id_Last_Updated")
                if "AENAM" in bpge.columns
                else F.lit(None).cast("string").alias("User_Id_Last_Updated"),
                F.lit(None).cast("string").alias("User_Defined_Fields"),
                F.lit(None).cast("string").alias("Valid_From"),
                F.lit(None).cast("string").alias("Valid_Until"),
                F.lit(None).cast("string").alias("Created"),
                F.lit(None).cast("string").alias("Created_By"),
                F.lit(None).cast("string").alias("Last_Updated"),
                F.lit(None).cast("string").alias("Last_Updated_By"),
            )
        )
        buddef_dfs.append(bpge_clean)

if buddef_dfs:
    from functools import reduce
    buddef_conformed = reduce(
        lambda a, b: a.unionByName(b, allowMissingColumns=True), buddef_dfs
    )
    buddef_conformed = buddef_conformed.filter(
        F.col("Budget_Code").isNotNull()
    ).dropDuplicates(["Business_Unit","Budget_Code"])

    print(f"Budget_Definitions rows: {buddef_conformed.count():,}")
    buddef_conformed.show(3, truncate=False)
    write_conformed(buddef_conformed, "Budget_Definitions")
```

```python
# ============================================================
# STEP 7 — Business_Unit_Addresses
# SAP: T001 (master-data) + ADRC (raw root)
# Target: 35 SunSystems columns
# ============================================================
t001 = safe_read(master_path,   "T001")
adrc = safe_read(raw_base_root, "ADRC")

if t001: print("\nT001 columns:", t001.columns)
if adrc: print("ADRC columns:", adrc.columns)
```

```python
if t001:
    t001_clean = (t001
        .filter(F.col("MANDT") == MANDT)
        if "MANDT" in t001.columns else t001
    )
    t001_clean = (t001_clean
        .dropDuplicates(["BUKRS"])
        .select(
            F.col("BUKRS"),
            F.col("ADRNR").alias("Address_Code")
            if "ADRNR" in t001.columns
            else F.lit(None).cast("string").alias("Address_Code"),
        )
    )

    bua_silver = t001_clean

    if adrc:
        adrc_clean = (adrc
            .filter(F.col("CLIENT") == MANDT)
            if "CLIENT" in adrc.columns else adrc
        )
        adrc_clean = (adrc_clean
            .dropDuplicates(["ADDRNUMBER"])
            .select(
                F.col("ADDRNUMBER").alias("Address_Code"),
                F.col("STREET").alias("Business_Unit_Address_Line_1")
                if "STREET" in adrc.columns
                else F.lit(None).cast("string").alias("Business_Unit_Address_Line_1"),
                F.col("STR_SUPPL1").alias("Business_Unit_Address_Line_2")
                if "STR_SUPPL1" in adrc.columns
                else F.lit(None).cast("string").alias("Business_Unit_Address_Line_2"),
                F.col("STR_SUPPL2").alias("Business_Unit_Address_Line_3")
                if "STR_SUPPL2" in adrc.columns
                else F.lit(None).cast("string").alias("Business_Unit_Address_Line_3"),
                F.col("CITY1").alias("Business_Unit_Address_Town_City")
                if "CITY1" in adrc.columns
                else F.lit(None).cast("string").alias("Business_Unit_Address_Town_City"),
                F.col("REGION").alias("Business_Unit_Address_State")
                if "REGION" in adrc.columns
                else F.lit(None).cast("string").alias("Business_Unit_Address_State"),
                F.col("COUNTRY").alias("Business_Unit_Address_Country")
                if "COUNTRY" in adrc.columns
                else F.lit(None).cast("string").alias("Business_Unit_Address_Country"),
                F.col("FAX_NUMBER").alias("Business_Unit_Address_Telex_Fax_Number")
                if "FAX_NUMBER" in adrc.columns
                else F.lit(None).cast("string").alias("Business_Unit_Address_Telex_Fax_Number"),
                F.col("LANGU").alias("Business_Unit_Address_Language_Code")
                if "LANGU" in adrc.columns
                else F.lit(None).cast("string").alias("Business_Unit_Address_Language_Code"),
                F.col("DATE_TO").alias("Business_Unit_Address_Date_Time_Last_Updated")
                if "DATE_TO" in adrc.columns
                else F.lit(None).cast("string").alias("Business_Unit_Address_Date_Time_Last_Updated"),
            )
        )
        bua_silver = t001_clean.join(adrc_clean, on="Address_Code", how="left")

    bua_conformed = (bua_silver
        .withColumnRenamed("BUKRS", "Business_Unit")
        .filter(F.col("Business_Unit").isNotNull())
    )

    # Add remaining SunSystems columns as nulls
    for col_name in ["Business_Unit_Address_Comment","Business_Unit_Address_Lookup_Code",
                     "Business_Unit_Address_Short_Heading","Business_Unit_Address_Status_Code",
                     "Business_Unit_Address_Status_Description","Business_Unit_Address_Temporary_Address_Code",
                     "Business_Unit_Address_Temporary_Address_Description","Business_Unit_Address_Update_Count",
                     "Business_Unit_Address_User_Id_Last_Updated","Date_Time_Last_Updated",
                     "Invoice_Address_Code","Own_Company_Code","Update_Count","User_Id_Last_Updated",
                     "User_Defined_Fields","Valid_From","Valid_Until","Created","Created_By",
                     "Last_Updated","Last_Updated_By"]:
        if col_name not in bua_conformed.columns:
            bua_conformed = bua_conformed.withColumn(col_name, F.lit(None).cast("string"))

    print(f"Business_Unit_Addresses rows: {bua_conformed.count():,}")
    bua_conformed.show(3, truncate=False)
    write_conformed(bua_conformed, "Business_Unit_Addresses")
```

```python
# ============================================================
# STEP 8 — Business_Unit_Details
# SAP: T001 (master-data) + ADRC (raw root) + T052 (co-budget)
# Target: 55 SunSystems columns
# ============================================================
t052 = safe_read(co_path, "T052")
if t052: print("\nT052 columns:", t052.columns)
```

```python
if t001:
    t001_clean2 = (t001
        .filter(F.col("MANDT") == MANDT)
        if "MANDT" in t001.columns else t001
    )
    t001_clean2 = (t001_clean2
        .dropDuplicates(["BUKRS"])
        .select(
            F.col("BUKRS").alias("Business_Unit"),
            F.col("BUTXT").alias("Name")
            if "BUTXT" in t001.columns
            else F.lit(None).cast("string").alias("Name"),
            F.col("BUTXT").alias("Description")
            if "BUTXT" in t001.columns
            else F.lit(None).cast("string").alias("Description"),
            F.col("ADRNR").alias("Invoice_Address_Code")
            if "ADRNR" in t001.columns
            else F.lit(None).cast("string").alias("Invoice_Address_Code"),
            F.col("KTOPL").alias("Own_Company_Code")
            if "KTOPL" in t001.columns
            else F.lit(None).cast("string").alias("Own_Company_Code"),
        )
    )

    bud_silver = t001_clean2

    if t052:
        t052_clean = (t052
            .filter(F.col("MANDT") == MANDT)
            if "MANDT" in t052.columns else t052
        )
        t052_clean = (t052_clean
            .dropDuplicates(["ZTERM"])
            .select(
                F.col("ZTERM").alias("Payment_Terms_Group_Code"),
                F.col("TEXT1").alias("Payment_Terms_Description")
                if "TEXT1" in t052.columns
                else F.lit(None).cast("string").alias("Payment_Terms_Description"),
            )
        )
        # Join on payment terms from T001
        if "DZTERM" in t001.columns:
            bud_silver = bud_silver.join(
                t052_clean.withColumnRenamed("Payment_Terms_Group_Code","dzterm_join"),
                bud_silver["DZTERM"] == t052_clean["dzterm_join"],
                how="left"
            ).drop("dzterm_join")
        else:
            bud_silver = bud_silver.withColumn("Payment_Terms_Group_Code", F.lit(None).cast("string"))
            bud_silver = bud_silver.withColumn("Payment_Terms_Description", F.lit(None).cast("string"))

    # Add all remaining target columns
    for col_name in ["Date_Time_Last_Updated","Email_Address","Invoice_Address_Line1","Invoice_Address_Line2",
                     "Invoice_Address_Line3","Invoice_Comment","Invoice_Country","Invoice_Date_Time_Last_Updated",
                     "Invoice_Language_Code","Invoice_Lookup_Code","Invoice_Short_Heading","Invoice_State",
                     "Invoice_Status_Code","Invoice_Status_Description","Invoice_Telephone_Number",
                     "InvoiceTelexFaxNumber","Invoice_Temporary_Address_Code","Invoice_Temporary_Address_Description",
                     "Invoice_Town_City","Invoice_Update_Count","Invoice_User_Id_Last_Updated","Lookup_Code",
                     "Payment_Receipt_Method_Code","Payment_Receipt_Method_Description",
                     "Payment_Terms_Date_Time_Last_Updated","Payment_Terms_Document1_Description",
                     "Payment_Terms_Document2_Description","Payment_Terms_Document3_Description",
                     "Payment_Terms_Document4_Description","Payment_Terms_Lookup_Code","Payment_Terms_Short_Heading",
                     "Payment_Terms_Update_Count","Payment_Terms_User_Id_Last_Updated",
                     "Preferred_Payment_Method_Code","Preferred_Payment_Method_Description","Short_Heading",
                     "Update_Count","User_Id_Last_Updated","Web_Page_Address","Valid_From","Valid_Until",
                     "Created","Created_By","Last_Updated","Last_Updated_By"]:
        if col_name not in bud_silver.columns:
            bud_silver = bud_silver.withColumn(col_name, F.lit(None).cast("string"))

    bud_conformed = bud_silver.filter(F.col("Business_Unit").isNotNull())
    print(f"Business_Unit_Details rows: {bud_conformed.count():,}")
    bud_conformed.show(3, truncate=False)
    write_conformed(bud_conformed, "Business_Unit_Details")
```

```python
# ============================================================
# STEP 9 — Business_Units
# SAP: T001 + TKA01 (master-data)
#      T005 (srm_ecc_raw_tables) + TCURR (reference-and-config)
# Target: 172 SunSystems columns — select key ones, null rest
# ============================================================
tcurr = safe_read(ref_path, "TCURR")
t005  = safe_read(srm_path, "T005")

if tcurr: print("\nTCURR columns:", tcurr.columns)
if t005:  print("T005  columns:", t005.columns)
```

```python
if t001:
    t001_bu = (t001
        .filter(F.col("MANDT") == MANDT)
        if "MANDT" in t001.columns else t001
    )
    t001_bu = (t001_bu
        .dropDuplicates(["BUKRS"])
        .select(
            F.col("BUKRS").alias("Business_Unit"),
            F.col("WAERS").alias("Base_Currency")
            if "WAERS" in t001.columns
            else F.lit(None).cast("string").alias("Base_Currency"),
            F.col("BUTXT").alias("Business_Unit_Description")
            if "BUTXT" in t001.columns
            else F.lit(None).cast("string").alias("Business_Unit_Description"),
            F.col("BUKRS").alias("Business_Unit_Code"),
            F.lit(12).cast("int").alias("Maximum_Number_Of_Periods"),
        )
    )

    bu_silver = t001_bu

    if tka01:
        tka01_bu = (tka01
            .filter(F.col("MANDT") == MANDT)
            if "MANDT" in tka01.columns else tka01
        )
        tka01_bu = (tka01_bu
            .dropDuplicates(["BUKRS"])
            .select(
                F.col("BUKRS").alias("Business_Unit"),
                F.col("WAERS").alias("Base_Currency_Description")
                if "WAERS" in tka01.columns
                else F.lit(None).cast("string").alias("Base_Currency_Description"),
            )
        )
        bu_silver = bu_silver.join(tka01_bu, on="Business_Unit", how="left")

    if tcurr:
        tcurr_bu = (tcurr
            .filter(F.col("MANDT") == MANDT)
            if "MANDT" in tcurr.columns else tcurr
        )
        tcurr_bu = (tcurr_bu
            .dropDuplicates(["FCURR"])
            .select(
                F.col("FCURR").alias("Base_Currency"),
                F.col("KURST").alias("Value3_Currency_Code")
                if "KURST" in tcurr.columns
                else F.lit(None).cast("string").alias("Value3_Currency_Code"),
            )
        )
        bu_silver = bu_silver.join(tcurr_bu, on="Base_Currency", how="left")

    # Pad all missing target cols as null
    target_cols_bu = [
        "Date_Time_Last_Updated","Business_Unit_Locked_Code","Business_Unit_Locked_Description",
        "Date_Format_Code","Date_Separator","Decimal_Separator","Thousand_Separator",
        "Financials_Only_Code","Primary_Budget_Ledger_Code","Purchase_Commitment_Ledger_Code",
        "User_Id_Last_Updated","Base_Currency_Iso_Currency_Code","Base_Currency_Name",
        "Base_Currency_Currency_Unit_Name","Base_Currency_Gain_Account_Realized",
        "Base_Currency_Gain_Account_Unrealized","Base_Currency_Net_Loss_Account_Realized",
        "Valid_From","Valid_Until","Created","Created_By","Last_Updated","Last_Updated_By"
    ]
    for col_name in target_cols_bu:
        if col_name not in bu_silver.columns:
            bu_silver = bu_silver.withColumn(col_name, F.lit(None).cast("string"))

    bu_conformed = bu_silver.filter(F.col("Business_Unit").isNotNull())
    print(f"Business_Units rows: {bu_conformed.count():,}")
    bu_conformed.show(3, truncate=False)
    write_conformed(bu_conformed, "Business_Units")
```

```python
# ============================================================
# STEP 10 — Chart_Of_Accounts
# SAP: SKA1 + SKB1 + SKAT — folder: master-data
# Target: 82 SunSystems columns
# ============================================================
ska1 = safe_read(master_path, "SKA1")
skb1 = safe_read(master_path, "SKB1")
skat = safe_read(master_path, "SKAT")

if ska1: print("\nSKA1 columns:", ska1.columns)
if skb1: print("SKB1 columns:", skb1.columns)
if skat: print("SKAT columns:", skat.columns)
```

```python
if ska1:
    ska1_clean = (ska1
        .filter(F.col("MANDT") == MANDT)
        .dropDuplicates(["KTOPL","SAKNR"])
        .select(
            F.col("KTOPL").alias("Business_Unit"),
            F.col("SAKNR").alias("Account_Code"),
            F.col("GVTYP").alias("Account_Type_Code")
            if "GVTYP" in ska1.columns
            else F.lit(None).cast("string").alias("Account_Type_Code"),
            F.col("XBILK").alias("Balance_Type_Code")
            if "XBILK" in ska1.columns
            else F.lit(None).cast("string").alias("Balance_Type_Code"),
            F.col("AEDAT").alias("DateTime_Last_Updated")
            if "AEDAT" in ska1.columns
            else F.lit(None).cast("string").alias("DateTime_Last_Updated"),
            F.col("MITKZ").alias("Accounting_Links_Allowed_Code")
            if "MITKZ" in ska1.columns
            else F.lit(None).cast("string").alias("Accounting_Links_Allowed_Code"),
            F.lit("A").alias("Status_Code"),
            F.lit("Active").alias("Status_Description"),
            F.col("AENAM").alias("User_Id_Last_Updated")
            if "AENAM" in ska1.columns
            else F.lit(None).cast("string").alias("User_Id_Last_Updated"),
        )
    )

    coa_silver = ska1_clean

    if skat:
        skat_clean = (skat
            .filter(F.col("MANDT") == MANDT)
            .filter(F.col("SPRAS") == "EN"
                    if "SPRAS" in skat.columns else F.lit(True))
            .dropDuplicates(["KTOPL","SAKNR"])
            .select(
                F.col("KTOPL").alias("Business_Unit"),
                F.col("SAKNR").alias("Account_Code"),
                F.col("TXT20").alias("Short_Heading")
                if "TXT20" in skat.columns
                else F.lit(None).cast("string").alias("Short_Heading"),
                F.col("TXT50").alias("Description")
                if "TXT50" in skat.columns
                else F.lit(None).cast("string").alias("Description"),
                F.col("TXT50").alias("Long_Description")
                if "TXT50" in skat.columns
                else F.lit(None).cast("string").alias("Long_Description"),
            )
        )
        coa_silver = coa_silver.join(
            skat_clean, on=["Business_Unit","Account_Code"], how="left"
        )

    if skb1:
        skb1_clean = (skb1
            .filter(F.col("MANDT") == MANDT)
            .dropDuplicates(["BUKRS","SAKNR"])
            .select(
                F.col("BUKRS").alias("Business_Unit"),
                F.col("SAKNR").alias("Account_Code"),
                F.col("XLOEV").alias("Debit_Or_Credit_Code")
                if "XLOEV" in skb1.columns
                else F.lit(None).cast("string").alias("Debit_Or_Credit_Code"),
                F.col("RGRUPPE").alias("Report_Group")
                if "RGRUPPE" in skb1.columns
                else F.lit(None).cast("string").alias("Report_Group"),
            )
        )
        # Prefer skb1 join on Account_Code only (BUKRS vs KTOPL mismatch)
        coa_silver = coa_silver.join(
            skb1_clean.drop("Business_Unit"),
            on="Account_Code", how="left"
        )

    # Add custom SunSystems extended cols as null
    for col_name in ["Allocation_In_Progress_Code","Allocation_In_Progress_Description",
                     "Balance_Type_Description","Banking_Currencies_Required_Code",
                     "Banking_Currencies_Required_Description","Lookup_Code","Account_Type_Description",
                     "Accounting_Links_Allowed_Description","Debit_Or_Credit_Description",
                     "Suppress_Revaluation_Code","Suppress_Revaluation_Description",
                     "aa08","managementAcc","cashflow","financialAcc","coaLevel1","coaLevel2",
                     "uap","cutback","costallocation","workingcapital",
                     "Valid_From","Valid_Until","Created","Created_By","Last_Updated","Last_Updated_By"]:
        if col_name not in coa_silver.columns:
            coa_silver = coa_silver.withColumn(col_name, F.lit(None).cast("string"))

    coa_conformed = coa_silver.filter(F.col("Account_Code").isNotNull())
    print(f"Chart_Of_Accounts rows: {coa_conformed.count():,}")
    coa_conformed.show(3, truncate=False)
    write_conformed(coa_conformed, "Chart_Of_Accounts")
```

```python
# ============================================================
# STEP 11 — Currencies
# SAP: TCURC (ref) + TCURT + TCURX (co-budget)
# Target: 38 SunSystems columns
# ============================================================
tcurc = safe_read(ref_path, "TCURC")
tcurt = safe_read(co_path,  "TCURT")
tcurx = safe_read(co_path,  "TCURX")

if tcurc: print("\nTCURC columns:", tcurc.columns)
if tcurt: print("TCURT columns:", tcurt.columns)
if tcurx: print("TCURX columns:", tcurx.columns)
```

```python
curr_dfs = []

if tcurc:
    tcurc_clean = (tcurc
        .filter(F.col("MANDT") == MANDT)
        if "MANDT" in tcurc.columns else tcurc
    )
    tcurc_clean = (tcurc_clean
        .dropDuplicates(["WAERS"])
        .select(
            F.col("WAERS").alias("Currency_Code"),
            F.lit(None).cast("string").alias("Business_Unit"),
            F.lit(None).cast("string").alias("Banking_Currency_code"),
            F.lit(None).cast("string").alias("Banking_Currency_Description"),
            F.lit(None).cast("string").alias("Currency_Gender_code"),
            F.lit(None).cast("string").alias("Currency_Gender_description"),
            F.lit(None).cast("string").alias("Currency_Name"),
            F.lit(None).cast("string").alias("Currency_Unit_Name"),
            F.lit(None).cast("string").alias("DateTime_Last_Updated"),
            F.lit(None).cast("string").alias("Decimals_Allowed_code"),
            F.lit(None).cast("string").alias("Decimals_Allowed_Description"),
            F.lit(None).cast("string").alias("First_Decimal_Name"),
            F.lit(None).cast("string").alias("Gain_Account_Realized"),
            F.lit(None).cast("string").alias("Gain_Account_Unrealized"),
            F.lit(None).cast("string").alias("Lookup_Code"),
            F.lit(None).cast("string").alias("Net_Loss_Account_Realized"),
            F.lit(None).cast("string").alias("Net_Loss_Account_Unrealized"),
            F.lit(None).cast("string").alias("Second_Decimal_Name"),
            F.col("ISOCD").alias("Short_Heading")
            if "ISOCD" in tcurc.columns
            else F.lit(None).cast("string").alias("Short_Heading"),
            F.lit(None).cast("string").alias("Split_Decimal_Naming_Code"),
            F.lit(None).cast("string").alias("Split_Decimal_Naming_Description"),
            F.lit("A").alias("Status_Code"),
            F.lit("Active").alias("Status_Description"),
            F.lit(None).cast("string").alias("Third_Decimal_Name"),
            F.lit(None).cast("string").alias("Use_Daily_Conversion_Rates_Code"),
            F.lit(None).cast("string").alias("Use_Daily_Conversion_Rates_Description"),
            F.lit(None).cast("string").alias("User_Id_Last_Updated"),
            F.lit(None).cast("string").alias("User_Defined_Fields"),
            F.lit(None).cast("string").alias("Valid_From"),
            F.lit(None).cast("string").alias("Valid_Until"),
            F.lit(None).cast("string").alias("Created"),
            F.lit(None).cast("string").alias("Created_By"),
            F.lit(None).cast("string").alias("Last_Updated"),
            F.lit(None).cast("string").alias("Last_Updated_By"),
        )
    )
    curr_dfs.append(tcurc_clean)

if tcurt:
    tcurt_clean = (tcurt
        .filter(F.col("MANDT") == MANDT)
        if "MANDT" in tcurt.columns else tcurt
    )
    tcurt_clean = (tcurt_clean
        .filter(F.col("SPRAS") == "EN"
                if "SPRAS" in tcurt.columns else F.lit(True))
        .dropDuplicates(["WAERS"])
        .select(
            F.col("WAERS").alias("Currency_Code"),
            F.col("LTEXT").alias("Currency_Name")
            if "LTEXT" in tcurt.columns
            else F.col("KTEXT").alias("Currency_Name")
            if "KTEXT" in tcurt.columns
            else F.lit(None).cast("string").alias("Currency_Name"),
        )
    )
    if curr_dfs:
        curr_dfs[0] = curr_dfs[0].join(
            tcurt_clean, on="Currency_Code", how="left"
        ).drop(tcurt_clean["Currency_Name"])
        curr_dfs[0] = curr_dfs[0].withColumn(
            "Currency_Name",
            F.coalesce(curr_dfs[0]["Currency_Name"], tcurt_clean["Currency_Name"])
            if "Currency_Name" in curr_dfs[0].columns
            else tcurt_clean["Currency_Name"]
        )

if curr_dfs:
    currencies_conformed = curr_dfs[0].filter(F.col("Currency_Code").isNotNull())
    print(f"Currencies rows: {currencies_conformed.count():,}")
    currencies_conformed.show(3, truncate=False)
    write_conformed(currencies_conformed, "Currencies")
```

```python
# ============================================================
# STEP 12 — Currency_Rate_Types
# SAP: TCURV — folder: reference-and-config
# Target: 17 SunSystems columns
# ============================================================
tcurv = safe_read(ref_path, "TCURV")
if tcurv: print("\nTCURV columns:", tcurv.columns)
```

```python
if tcurv:
    tcurv_clean = (tcurv
        .filter(F.col("MANDT") == MANDT)
        if "MANDT" in tcurv.columns else tcurv
    )
    crt_conformed = (tcurv_clean
        .dropDuplicates(["KURST"])
        .select(
            F.lit(None).cast("string").alias("Business_Unit"),
            F.col("KURST").alias("Currency_Rate_Type"),
            F.col("AEDAT").alias("Date_Time_Last_Updated")
            if "AEDAT" in tcurv.columns
            else F.lit(None).cast("string").alias("Date_Time_Last_Updated"),
            F.col("LTEXT").alias("Description")
            if "LTEXT" in tcurv.columns
            else F.col("KTEXT").alias("Description")
            if "KTEXT" in tcurv.columns
            else F.lit(None).cast("string").alias("Description"),
            F.lit(None).cast("string").alias("Lookup_Code"),
            F.col("KURST").alias("Short_Heading"),
            F.col("AENAM").alias("User_Id_Last_Updated")
            if "AENAM" in tcurv.columns
            else F.lit(None).cast("string").alias("User_Id_Last_Updated"),
            F.lit(None).cast("string").alias("Valid_From"),
            F.lit(None).cast("string").alias("Valid_Until"),
            F.lit(None).cast("string").alias("Created"),
            F.lit(None).cast("string").alias("Created_By"),
            F.lit(None).cast("string").alias("Last_Updated"),
            F.lit(None).cast("string").alias("Last_Updated_By"),
        )
        .filter(F.col("Currency_Rate_Type").isNotNull())
    )
    print(f"Currency_Rate_Types rows: {crt_conformed.count():,}")
    crt_conformed.show(5, truncate=False)
    write_conformed(crt_conformed, "Currency_Rate_Types")
```

```python
# ============================================================
# STEP 13 — Employee_Roles
# SAP: HRP1001 + AGR_USERS (hr) + PA0001 (master-data)
# Target: 18 SunSystems columns
# ============================================================
hrp1001   = safe_read(hr_path,     "HRP1001")
agr_users = safe_read(hr_path,     "AGR_USERS")
pa0001    = safe_read(master_path, "PA0001")

if hrp1001:   print("\nHRP1001   columns:", hrp1001.columns)
if agr_users: print("AGR_USERS columns:", agr_users.columns)
if pa0001:    print("PA0001    columns:", pa0001.columns)
```

```python
er_dfs = []

if agr_users:
    agr_clean = (agr_users
        .filter(F.col("MANDT") == MANDT)
        if "MANDT" in agr_users.columns else agr_users
    )
    agr_clean = (agr_clean
        .dropDuplicates(["UNAME","AGR_NAME"])
        .select(
            F.lit(None).cast("string").alias("Business_Unit"),
            F.lit("Y").alias("Active_Employee_Role_Code"),
            F.lit("Active").alias("Active_Employee_Role_Description"),
            F.col("AEDAT").alias("Date_Time_Last_Updated")
            if "AEDAT" in agr_users.columns
            else F.lit(None).cast("string").alias("Date_Time_Last_Updated"),
            F.col("UNAME").alias("Employee_Code"),
            F.col("AGR_NAME").alias("Role_Code"),
            F.col("AGR_NAME").alias("Role_Description"),
            F.col("AENAM").alias("User_Id_Last_Updated")
            if "AENAM" in agr_users.columns
            else F.lit(None).cast("string").alias("User_Id_Last_Updated"),
            F.lit(None).cast("string").alias("Valid_From"),
            F.lit(None).cast("string").alias("Valid_Until"),
            F.lit(None).cast("string").alias("Created"),
            F.lit(None).cast("string").alias("Created_By"),
            F.lit(None).cast("string").alias("Last_Updated"),
            F.lit(None).cast("string").alias("Last_Updated_By"),
        )
    )
    er_dfs.append(agr_clean)

if hrp1001:
    hrp_clean = (hrp1001
        .filter(F.col("MANDT") == MANDT)
        if "MANDT" in hrp1001.columns else hrp1001
    )
    hrp_clean = (hrp_clean
        .dropDuplicates(["OBJID","SUBTY"])
        .select(
            F.lit(None).cast("string").alias("Business_Unit"),
            F.lit("Y").alias("Active_Employee_Role_Code"),
            F.lit("Active").alias("Active_Employee_Role_Description"),
            F.col("ENDDA").alias("Date_Time_Last_Updated")
            if "ENDDA" in hrp1001.columns
            else F.lit(None).cast("string").alias("Date_Time_Last_Updated"),
            F.col("OBJID").alias("Employee_Code"),
            F.col("SUBTY").alias("Role_Code"),
            F.col("STEXT").alias("Role_Description")
            if "STEXT" in hrp1001.columns
            else F.lit(None).cast("string").alias("Role_Description"),
            F.col("AENAM").alias("User_Id_Last_Updated")
            if "AENAM" in hrp1001.columns
            else F.lit(None).cast("string").alias("User_Id_Last_Updated"),
            F.col("BEGDA").alias("Valid_From")
            if "BEGDA" in hrp1001.columns
            else F.lit(None).cast("string").alias("Valid_From"),
            F.col("ENDDA").alias("Valid_Until")
            if "ENDDA" in hrp1001.columns
            else F.lit(None).cast("string").alias("Valid_Until"),
            F.lit(None).cast("string").alias("Created"),
            F.lit(None).cast("string").alias("Created_By"),
            F.lit(None).cast("string").alias("Last_Updated"),
            F.lit(None).cast("string").alias("Last_Updated_By"),
        )
    )
    er_dfs.append(hrp_clean)

if er_dfs:
    from functools import reduce
    er_conformed = reduce(
        lambda a, b: a.unionByName(b, allowMissingColumns=True), er_dfs
    )
    er_conformed = er_conformed.filter(F.col("Employee_Code").isNotNull())
    print(f"Employee_Roles rows: {er_conformed.count():,}")
    er_conformed.show(3, truncate=False)
    write_conformed(er_conformed, "Employee_Roles")
```

```python
# ============================================================
# STEP 14 — Fixed_Assets
# SAP: ANLA + ANLB (master-data) + ANLC + ANLZ (pm-asset-events)
# Target: 86 SunSystems columns
# ============================================================
anla = safe_read(master_path, "ANLA")
anlb = safe_read(master_path, "ANLB")
anlc = safe_read(pm_path,     "ANLC")
anlz = safe_read(pm_path,     "ANLZ")

if anla: print("\nANLA columns:", anla.columns)
if anlb: print("ANLB columns:", anlb.columns)
if anlc: print("ANLC columns:", anlc.columns)
if anlz: print("ANLZ columns:", anlz.columns)
```

```python
if anla:
    anla_clean = (anla
        .filter(F.col("MANDT") == MANDT)
        .dropDuplicates(["BUKRS","ANLN1"])
        .select(
            F.col("BUKRS").alias("Business_Unit"),
            F.col("ANLKL").alias("Asset_Class_Code")
            if "ANLKL" in anla.columns
            else F.lit(None).cast("string").alias("Asset_Class_Code"),
            F.col("ANLN1").alias("Asset_Code"),
            F.col("WAERS").alias("Asset_Currency_Code")
            if "WAERS" in anla.columns
            else F.lit(None).cast("string").alias("Asset_Currency_Code"),
            F.lit(None).cast("float").alias("Asset_Quantity"),
            F.col("DEAKT").alias("Asset_Status_Code")
            if "DEAKT" in anla.columns
            else F.lit(None).cast("string").alias("Asset_Status_Code"),
            F.lit(None).cast("string").alias("Asset_Status_Description"),
            F.lit(None).cast("int").alias("Balance_Sheet"),
            F.col("AEDAT").alias("Date_Time_Last_Updated")
            if "AEDAT" in anla.columns
            else F.lit(None).cast("string").alias("Date_Time_Last_Updated"),
            F.col("TXT50").alias("Description")
            if "TXT50" in anla.columns
            else F.lit(None).cast("string").alias("Description"),
            F.col("XABGANG").alias("Disposed_Code")
            if "XABGANG" in anla.columns
            else F.lit(None).cast("string").alias("Disposed_Code"),
            F.lit(None).cast("string").alias("Disposed_Description"),
            F.col("ANLKL").alias("Short_Heading")
            if "ANLKL" in anla.columns
            else F.lit(None).cast("string").alias("Short_Heading"),
            F.lit("A").alias("Status_Code"),
            F.lit("Active").alias("Status_Description"),
            F.col("AENAM").alias("User_Id_Last_Updated")
            if "AENAM" in anla.columns
            else F.lit(None).cast("string").alias("User_Id_Last_Updated"),
        )
    )

    fa_silver = anla_clean

    if anlb:
        anlb_clean = (anlb
            .filter(F.col("MANDT") == MANDT)
            .dropDuplicates(["BUKRS","ANLN1","AFABE"])
            .select(
                F.col("BUKRS").alias("Business_Unit"),
                F.col("ANLN1").alias("Asset_Code"),
                F.col("AFASL").alias("Base_Depreciation_Method_Code")
                if "AFASL" in anlb.columns
                else F.lit(None).cast("string").alias("Base_Depreciation_Method_Code"),
                F.lit(None).cast("string").alias("Base_Depreciation_Method_Description"),
                F.col("PROZ").cast("float").alias("Base_Percentage")
                if "PROZ" in anlb.columns
                else F.lit(None).cast("float").alias("Base_Percentage"),
            )
        )
        fa_silver = fa_silver.join(anlb_clean, on=["Business_Unit","Asset_Code"], how="left")

    if anlc:
        anlc_clean = (anlc
            .filter(F.col("MANDT") == MANDT)
            .dropDuplicates(["BUKRS","ANLN1","AFABE","GJAHR"])
            .select(
                F.col("BUKRS").alias("Business_Unit"),
                F.col("ANLN1").alias("Asset_Code"),
                F.col("ANSWT").cast("float").alias("Base_Gross_Value")
                if "ANSWT" in anlc.columns
                else F.lit(None).cast("float").alias("Base_Gross_Value"),
                F.col("KANSW").cast("float").alias("Base_Net_Value")
                if "KANSW" in anlc.columns
                else F.lit(None).cast("float").alias("Base_Net_Value"),
                F.col("NAFAB").cast("float").alias("Base_Depreciation_Value")
                if "NAFAB" in anlc.columns
                else F.lit(None).cast("float").alias("Base_Depreciation_Value"),
            )
        )
        fa_silver = fa_silver.join(anlc_clean, on=["Business_Unit","Asset_Code"], how="left")

    # Add remaining SunSystems asset cols as nulls
    for col_name in ["Part_Disposed_Code","Part_Disposed_Description","Profit_And_Loss",
                     "Reporting_Depreciation_Method_Code","Reporting_Depreciation_Method_Description",
                     "Report_Gross_Value","Report_Net_Value","Report_Depreciation_Value",
                     "Start_Period","Last_Period","Lookup_Code","Fa05","Fa06","Fa07","Fa08","Fa09","Fa10",
                     "Asset_Maintain","Asset_Location","Asset_Class_1","locations","afe",
                     "legacyAssetCo","legacySupplier","Valid_From","Valid_Until",
                     "Created","Created_By","Last_Updated","Last_Updated_By"]:
        if col_name not in fa_silver.columns:
            fa_silver = fa_silver.withColumn(col_name, F.lit(None).cast("string"))

    fa_conformed = fa_silver.filter(F.col("Asset_Code").isNotNull())
    print(f"Fixed_Assets rows: {fa_conformed.count():,}")
    fa_conformed.show(3, truncate=False)
    write_conformed(fa_conformed, "Fixed_Assets")
```

```python
# ============================================================
# STEP 15 — Journal_Definitions
# SAP: T003 + T003T — folder: reference-and-config
# Target: 154 SunSystems columns
# ============================================================
t003  = safe_read(ref_path, "T003")
t003t = safe_read(ref_path, "T003T")

if t003:  print("\nT003  columns:", t003.columns)
if t003t: print("T003T columns:", t003t.columns)
```

```python
if t003:
    t003_clean = (t003
        .filter(F.col("MANDT") == MANDT)
        if "MANDT" in t003.columns else t003
    )
    t003_clean = (t003_clean
        .dropDuplicates(["BLART"])
        .select(
            F.lit(None).cast("string").alias("Business_Unit"),
            F.col("BLART").alias("Journal_Type"),
            F.col("AEDAT").alias("Date_Time_Last_Updated")
            if "AEDAT" in t003.columns
            else F.lit(None).cast("string").alias("Date_Time_Last_Updated"),
            F.lit(None).cast("string").alias("Allocation_Marker_Code"),
            F.lit(None).cast("string").alias("Allocation_Marker_Description"),
            F.lit(None).cast("string").alias("Allow_Scheduled_Payments_Code"),
            F.lit(None).cast("string").alias("Allow_Scheduled_Payments_Description"),
            F.lit(None).cast("string").alias("Asset_Depreciation_Type_Code"),
            F.lit(None).cast("string").alias("Asset_Sale_Code"),
            F.lit(None).cast("string").alias("Authorization_Required_Code"),
            F.lit(None).cast("string").alias("Journal_Name"),
            F.lit(None).cast("string").alias("Journal_Preset_Code"),
            F.lit(None).cast("string").alias("Rate_Type"),
            F.lit("A").alias("Record_Status_Code"),
            F.lit("Active").alias("Record_Status_Description"),
            F.lit(None).cast("string").alias("Reverse_Next_Period_Code"),
            F.lit(None).cast("string").alias("Sequence_Number_Code"),
            F.lit(None).cast("string").alias("Transaction_Post_Rule_Override_Code"),
            F.lit(None).cast("string").alias("True_Rated_Code"),
            F.lit(None).cast("float").alias("Discount_Tolerance_Days"),
            F.lit(None).cast("float").alias("Discount_Tolerance_Percentage"),
            F.lit(None).cast("float").alias("Discount_Tolerance_Value"),
            F.col("AENAM").alias("User_Id_Last_Updated")
            if "AENAM" in t003.columns
            else F.lit(None).cast("string").alias("User_Id_Last_Updated"),
            F.lit(None).cast("string").alias("User_Defined_Fields"),
            F.lit(None).cast("string").alias("Valid_From"),
            F.lit(None).cast("string").alias("Valid_Until"),
            F.lit(None).cast("string").alias("Created"),
            F.lit(None).cast("string").alias("Created_By"),
            F.lit(None).cast("string").alias("Last_Updated"),
            F.lit(None).cast("string").alias("Last_Updated_By"),
        )
    )

    jd_silver = t003_clean

    if t003t:
        t003t_clean = (t003t
            .filter(F.col("MANDT") == MANDT)
            if "MANDT" in t003t.columns else t003t
        )
        t003t_clean = (t003t_clean
            .filter(F.col("SPRAS") == "EN"
                    if "SPRAS" in t003t.columns else F.lit(True))
            .dropDuplicates(["BLART"])
            .select(
                F.col("BLART").alias("Journal_Type"),
                F.col("LTEXT").alias("Journal_Name"),
            )
        )
        jd_silver = jd_silver.join(
            t003t_clean, on="Journal_Type", how="left"
        ).drop(t003t_clean["Journal_Name"])
        jd_silver = jd_silver.withColumn(
            "Journal_Name",
            F.coalesce(
                F.col("Journal_Name"),
                t003t_clean["Journal_Name"]
            ) if "Journal_Name" in jd_silver.columns
            else t003t_clean["Journal_Name"]
        )

    jd_conformed = jd_silver.filter(F.col("Journal_Type").isNotNull())
    print(f"Journal_Definitions rows: {jd_conformed.count():,}")
    jd_conformed.show(3, truncate=False)
    write_conformed(jd_conformed, "Journal_Definitions")
```

```python
# ============================================================
# STEP 16 — Ledger_Lines
# SAP: BKPF + BSEG (transaction-data) + BSIS + BSAS (co-budget)
# Target: 165 SunSystems columns — most critical financial table
# ============================================================
bkpf = safe_read(tx_path, "BKPF")
bseg = safe_read(tx_path, "BSEG")
bsis = safe_read(co_path, "BSIS")
bsas = safe_read(co_path, "BSAS")

if bkpf: print(f"\nBKPF rows: {bkpf.count():,}")
if bseg: print(f"BSEG rows: {bseg.count():,}")
if bsis: print(f"BSIS rows: {bsis.count():,}")
if bsas: print(f"BSAS rows: {bsas.count():,}")
```

```python
if bseg and bkpf:
    bkpf_clean = (bkpf
        .filter(F.col("MANDT") == MANDT)
        .dropDuplicates(["BELNR","BUKRS","GJAHR"])
        .select(
            F.col("BUKRS"),
            F.col("BELNR"),
            F.col("GJAHR"),
            F.col("BLART").alias("Journal_Type"),
            F.to_date(F.col("BUDAT"), "yyyyMMdd").alias("Accounting_Period_Date"),
            F.to_date(F.col("BLDAT"), "yyyyMMdd").alias("Entry_Date"),
            F.col("XBLNR").alias("Transaction_Reference")
            if "XBLNR" in bkpf.columns
            else F.lit(None).cast("string").alias("Transaction_Reference"),
            F.col("USNAM").alias("Created_By_User")
            if "USNAM" in bkpf.columns
            else F.lit(None).cast("string").alias("Created_By_User"),
        )
    )

    bseg_clean = (bseg
        .filter(F.col("MANDT") == MANDT)
        .dropDuplicates(["BELNR","BUKRS","GJAHR","BUZEI"])
        .select(
            F.col("BUKRS").alias("Business_Unit"),
            F.col("HKONT").alias("Account_Code"),
            F.col("BELNR").alias("Journal_Number"),
            F.col("BUZEI").alias("Journal_Line_Number"),
            F.col("GJAHR"),
            F.col("BELNR"),
            F.col("BUKRS"),
            F.col("WAERS").alias("Currency_Code")
            if "WAERS" in bseg.columns
            else F.lit(None).cast("string").alias("Currency_Code"),
            F.col("SHKZG").alias("Debit_Credit_Code")
            if "SHKZG" in bseg.columns
            else F.lit(None).cast("string").alias("Debit_Credit_Code"),
            F.col("SGTXT").alias("Description")
            if "SGTXT" in bseg.columns
            else F.lit(None).cast("string").alias("Description"),
            F.to_date(F.col("ZFBDT"), "yyyyMMdd").alias("Due_Date")
            if "ZFBDT" in bseg.columns
            else F.lit(None).cast("date").alias("Due_Date"),
            F.col("WRBTR").cast("float").alias("Transaction_Amount")
            if "WRBTR" in bseg.columns
            else F.lit(None).cast("float").alias("Transaction_Amount"),
            F.col("DMBTR").cast("float").alias("Base_Amount_Amount")
            if "DMBTR" in bseg.columns
            else F.lit(None).cast("float").alias("Base_Amount_Amount"),
            F.col("LIFNR").alias("Supplier")
            if "LIFNR" in bseg.columns
            else F.lit(None).cast("string").alias("Supplier"),
            F.col("KOSTL").alias("Locations")
            if "KOSTL" in bseg.columns
            else F.lit(None).cast("string").alias("Locations"),
            F.col("AUFNR").alias("Afe")
            if "AUFNR" in bseg.columns
            else F.lit(None).cast("string").alias("Afe"),
            F.col("PROJN").alias("Wbs")
            if "PROJN" in bseg.columns
            else F.lit(None).cast("string").alias("Wbs"),
        )
    )

    ll_silver = bseg_clean.join(bkpf_clean, on=["BELNR","BUKRS","GJAHR"], how="left")

    # Build remaining SunSystems Ledger_Lines columns
    ll_silver = (ll_silver
        .withColumn("Accounting_Period",
            F.date_format(F.col("Accounting_Period_Date"), "yyyyMM"))
        .withColumn("Journal_Source", F.lit("SAP_ECC"))
        .withColumn("Ledger_Code", F.lit(None).cast("string"))
        .withColumn("Transaction_Amount_Currency_Code", F.col("Currency_Code"))
        .withColumn("Transaction_Credit_Amount",
            F.when(F.col("Debit_Credit_Code") == "H", F.col("Transaction_Amount"))
             .otherwise(F.lit(0.0)))
        .withColumn("Transaction_Debit_Amount",
            F.when(F.col("Debit_Credit_Code") == "S", F.col("Transaction_Amount"))
             .otherwise(F.lit(0.0)))
        .withColumn("Base_Credit_Amount",
            F.when(F.col("Debit_Credit_Code") == "H", F.col("Base_Amount_Amount"))
             .otherwise(F.lit(0.0)))
        .withColumn("Base_Debit_Amount",
            F.when(F.col("Debit_Credit_Code") == "S", F.col("Base_Amount_Amount"))
             .otherwise(F.lit(0.0)))
    )

    # Add all remaining SunSystems LL columns as nulls
    for col_name in [
        "Agreed_Status_Code","Agreed_Status_Description","Allocation_In_Progress",
        "Allocation_Marker_Code","Allocation_Marker_Description","Allocation_Period",
        "Allocation_Reference","Base2_Reporting_Amount","Reporting_Credit_Amount",
        "Reporting_Debit_Amount","Base2_Reporting_Rate","Base_Rate","Currency_Rate",
        "Entry_Period","Tax","Entityjv","Billing","Lifecycle","Uap","Jvbilling",
        "Summarycoa","Managementacc","Whtstate","Narration","Workingcapital","Cashflow",
        "Financialacc","Coalevel1","Coalevel2","Cutback","Costallocation","Paidgovernment",
        "Contract","Product","Project","Employee","Department","London_office","Legacyassetco",
        "Legacysupplier","La09","La10","Aa08","Transaction_Reference","Valid_From","Valid_Until",
        "Created","Last_Updated","Last_Updated_By"
    ]:
        if col_name not in ll_silver.columns:
            ll_silver = ll_silver.withColumn(col_name, F.lit(None).cast("string"))

    ll_conformed = ll_silver.filter(F.col("Account_Code").isNotNull())
    print(f"Ledger_Lines rows: {ll_conformed.count():,}")
    ll_conformed.show(3, truncate=False)
    write_conformed(ll_conformed, "Ledger_Lines")
else:
    print("⚠️ BSEG or BKPF not available — Ledger_Lines skipped")
```

```python
# ============================================================
# STEP 17 — Ledger_Setups
# SAP: T011 + T093 + T093B — folder: co-budget
# Target: 198 SunSystems columns
# ============================================================
t011  = safe_read(co_path, "T011")
t093  = safe_read(co_path, "T093")
t093b = safe_read(co_path, "T093B")

if t011:  print("\nT011  columns:", t011.columns)
if t093:  print("T093  columns:", t093.columns)
if t093b: print("T093B columns:", t093b.columns)
```

```python
ls_dfs = []

for tbl_name, df in [("T011", t011), ("T093", t093), ("T093B", t093b)]:
    if df:
        df_clean = (df
            .filter(F.col("MANDT") == MANDT)
            if "MANDT" in df.columns else df
        )
        key_col = next((c for c in ["VERSN","LDGDEF","BUKRS","AFAPL"] if c in df.columns), None)
        if key_col:
            df_clean = (df_clean
                .dropDuplicates([key_col])
                .select(
                    F.col("BUKRS").alias("Business_Unit")
                    if "BUKRS" in df.columns
                    else F.lit(None).cast("string").alias("Business_Unit"),
                    F.col(key_col).alias("Ledger_Definition_Id"),
                    F.col("AEDAT").alias("Date_Time_Last_Updated")
                    if "AEDAT" in df.columns
                    else F.lit(None).cast("string").alias("Date_Time_Last_Updated"),
                    F.lit("A").alias("Status_Code"),
                    F.lit("Active").alias("Status_Description"),
                    F.lit(None).cast("string").alias("Open_Period_From"),
                    F.lit(None).cast("string").alias("Open_Period_To"),
                    F.lit(None).cast("date").alias("Open_Date_From"),
                    F.lit(None).cast("date").alias("Open_Date_To"),
                    F.lit(None).cast("string").alias("Current_Period"),
                    F.col("AENAM").alias("User_Id_Last_Updated")
                    if "AENAM" in df.columns
                    else F.lit(None).cast("string").alias("User_Id_Last_Updated"),
                    F.lit(None).cast("string").alias("Valid_From"),
                    F.lit(None).cast("string").alias("Valid_Until"),
                    F.lit(None).cast("string").alias("Created"),
                    F.lit(None).cast("string").alias("Created_By"),
                    F.lit(None).cast("string").alias("Last_Updated"),
                    F.lit(None).cast("string").alias("Last_Updated_By"),
                )
            )
            ls_dfs.append(df_clean)
            print(f"{tbl_name} clean rows: {df_clean.count():,}")

if ls_dfs:
    from functools import reduce
    ls_conformed = reduce(
        lambda a, b: a.unionByName(b, allowMissingColumns=True), ls_dfs
    )
    ls_conformed = ls_conformed.filter(F.col("Ledger_Definition_Id").isNotNull())
    print(f"Ledger_Setups rows: {ls_conformed.count():,}")
    ls_conformed.show(3, truncate=False)
    write_conformed(ls_conformed, "Ledger_Setups")
```

```python
# ============================================================
# STEP 18 — Supplier_Region
# SAP: T005U (co-budget) + LFA1 (raw root)
# Target: 2 SunSystems columns (Region + Description)
# ============================================================
t005u = safe_read(co_path,      "T005U")
lfa1  = safe_read(raw_base_root, "LFA1")

if t005u: print("\nT005U columns:", t005u.columns)
if lfa1:  print("LFA1  columns:", lfa1.columns)
```

```python
sr_dfs = []

if t005u:
    t005u_clean = (t005u
        .filter(F.col("MANDT") == MANDT)
        if "MANDT" in t005u.columns else t005u
    )
    t005u_clean = (t005u_clean
        .dropDuplicates(["BLAND","LAND1"])
        .select(
            F.col("BLAND").alias("Region"),
            F.col("BEZEI").alias("Description")
            if "BEZEI" in t005u.columns
            else F.lit(None).cast("string").alias("Description"),
        )
    )
    sr_dfs.append(t005u_clean)

if lfa1:
    # Extract distinct regions from LFA1 vendor master
    lfa1_region = (lfa1
        .filter(F.col("MANDT") == MANDT)
        .filter(F.col("REGIO").isNotNull())
        .dropDuplicates(["REGIO"])
        .select(
            F.col("REGIO").alias("Region"),
            F.col("REGIO").alias("Description"),
        )
    )
    sr_dfs.append(lfa1_region)

if sr_dfs:
    from functools import reduce
    sr_conformed = reduce(
        lambda a, b: a.unionByName(b, allowMissingColumns=True), sr_dfs
    )
    sr_conformed = (sr_conformed
        .filter(F.col("Region").isNotNull())
        .dropDuplicates(["Region"])
    )
    print(f"Supplier_Region rows: {sr_conformed.count():,}")
    sr_conformed.show(5, truncate=False)
    write_conformed(sr_conformed, "Supplier_Region")
```

```python
# ============================================================
# STEP 19 — Suppliers
# SAP: LFA1 (raw root) + LFB1 (master-data)
#      + LFM1 + LFBK (raw root)
# Target: 65 SunSystems columns
# ============================================================
lfa1 = safe_read(raw_base_root, "LFA1")
lfb1 = safe_read(master_path,   "LFB1")
lfm1 = safe_read(raw_base_root, "LFM1")
lfbk = safe_read(raw_base_root, "LFBK")

if lfa1: print(f"\nLFA1 rows: {lfa1.count():,}")
if lfb1: print(f"LFB1 rows: {lfb1.count():,}")
if lfm1: print(f"LFM1 rows: {lfm1.count():,}")
if lfbk: print(f"LFBK rows: {lfbk.count():,}")
```

```python
if lfa1:
    lfa1_clean = (lfa1
        .filter(F.col("MANDT") == MANDT)
        .dropDuplicates(["LIFNR"])
        .select(
            F.lit(None).cast("string").alias("Business_Unit"),
            F.col("LIFNR").alias("Account_Code"),
            F.col("LIFNR").alias("Supplier_Code"),
            F.col("NAME1").alias("Supplier_Name")
            if "NAME1" in lfa1.columns
            else F.lit(None).cast("string").alias("Supplier_Name"),
            F.col("ADRNR").alias("Company_Address_Code")
            if "ADRNR" in lfa1.columns
            else F.lit(None).cast("string").alias("Company_Address_Code"),
            F.col("STCD1").alias("whtState")
            if "STCD1" in lfa1.columns
            else F.lit(None).cast("string").alias("whtState"),
            F.lit(None).cast("string").alias("narration"),
            F.lit(None).cast("string").alias("london_office"),
            F.lit(None).cast("string").alias("paidGoverment"),
            F.col("KTOKK").alias("Short_Heading")
            if "KTOKK" in lfa1.columns
            else F.lit(None).cast("string").alias("Short_Heading"),
            F.when(F.col("SPERR") == "X", "I")
             .otherwise("A").alias("Status_Code"),
            F.when(F.col("SPERR") == "X", "Inactive")
             .otherwise("Active").alias("Status_Description"),
            F.col("ERDAT").alias("Date_Time_Last_Updated")
            if "ERDAT" in lfa1.columns
            else F.lit(None).cast("string").alias("Date_Time_Last_Updated"),
            F.lit(None).cast("string").alias("Lookup_Code"),
            F.lit(None).cast("string").alias("Description"),
        )
    )

    sup_silver = lfa1_clean

    if lfb1:
        lfb1_clean = (lfb1
            .filter(F.col("MANDT") == MANDT)
            .dropDuplicates(["LIFNR","BUKRS"])
            .select(
                F.col("LIFNR").alias("Supplier_Code"),
                F.col("BUKRS").alias("Business_Unit"),
                F.col("ZTERM").alias("Payment_Terms_Group_Code")
                if "ZTERM" in lfb1.columns
                else F.lit(None).cast("string").alias("Payment_Terms_Group_Code"),
                F.col("ZLSCH").alias("Payment_Method_Code")
                if "ZLSCH" in lfb1.columns
                else F.lit(None).cast("string").alias("Payment_Method_Code"),
                F.col("WAERS").alias("Default_Currency_Code")
                if "WAERS" in lfb1.columns
                else F.lit(None).cast("string").alias("Default_Currency_Code"),
            )
        )
        sup_silver = sup_silver.join(
            lfb1_clean, on="Supplier_Code", how="left"
        )

    if lfm1:
        lfm1_clean = (lfm1
            .filter(F.col("MANDT") == MANDT)
            .dropDuplicates(["LIFNR","EKORG"])
            .select(
                F.col("LIFNR").alias("Supplier_Code"),
                F.col("WAERS").alias("Currency")
                if "WAERS" in lfm1.columns
                else F.lit(None).cast("string").alias("Currency"),
            )
        )
        sup_silver = sup_silver.join(
            lfm1_clean, on="Supplier_Code", how="left"
        )

    # Add remaining SunSystems extended cols
    for col_name in ["Carrier_Code","Carrier_Description","Comment","Credit_Check_Warning_Limit",
                     "Days_Tolerance_Override_Code","Days_Tolerance_Override_Description",
                     "Direct_Debit_Code","Direct_Debit_Description","Distribution_Format_Code",
                     "Distribution_Method_Code","Earliest_Latest_Cost_Code","Imminent_Settlement_Code",
                     "Maintain_Statistics_Code","Payment_Method_Description","Tolerance_Days_To_Apply",
                     "Price_List","sa05","sa06","sa07","sa08","sa09","sa10",
                     "Update_Count","User_Id_Last_Updated","Valid_From","Valid_Until",
                     "Created","Created_By","Last_Updated","Last_Updated_By"]:
        if col_name not in sup_silver.columns:
            sup_silver = sup_silver.withColumn(col_name, F.lit(None).cast("string"))

    sup_conformed = sup_silver.filter(F.col("Supplier_Code").isNotNull())
    print(f"Suppliers rows: {sup_conformed.count():,}")
    sup_conformed.show(3, truncate=False)
    write_conformed(sup_conformed, "Suppliers")
```

```python
# ============================================================
# STEP 20 — DateDimension
# SAP: SCAL_TT_DATE + SCAL_TT_MONTH + SCAL_TT_WEEK +
#      SCAL_TT_YEAR + SCALTT_MONTH + SCALTT_TYP +
#      SCALT_CONV + SCALT_MONTH + SCALT_TYPE + TFACS
#      folder: eam_ecc_raw_tables
# Target: 28 SunSystems DateDimension columns
# ============================================================
scal_date  = safe_read(eam_path, "SCAL_TT_DATE")
scal_month = safe_read(eam_path, "SCAL_TT_MONTH")
scal_week  = safe_read(eam_path, "SCAL_TT_WEEK")
scal_year  = safe_read(eam_path, "SCAL_TT_YEAR")
tfacs      = safe_read(eam_path, "TFACS")

if scal_date:  print("\nSCAL_TT_DATE  columns:", scal_date.columns)
if scal_month: print("SCAL_TT_MONTH columns:", scal_month.columns)
if scal_week:  print("SCAL_TT_WEEK  columns:", scal_week.columns)
if scal_year:  print("SCAL_TT_YEAR  columns:", scal_year.columns)
if tfacs:      print("TFACS         columns:", tfacs.columns)
```

```python
if scal_date:
    # Build DateDimension from SCAL_TT_DATE as primary source
    date_col = next((c for c in ["DATE","DATUM","CALDT","KADAT"] if c in scal_date.columns), None)
    print(f"SCAL_TT_DATE date column: {date_col}")

    if date_col:
        dd = (scal_date
            .dropDuplicates([date_col])
            .select(F.col(date_col).cast("date").alias("Date"))
            .filter(F.col("Date").isNotNull())
        )

        # Generate all SunSystems DateDimension columns from date
        dd_conformed = (dd
            .select(
                F.col("Date"),
                F.dayofmonth(F.col("Date")).cast("short").alias("Day"),
                F.when(F.dayofmonth(F.col("Date")).isin([1,21,31]), "st")
                 .when(F.dayofmonth(F.col("Date")).isin([2,22]),    "nd")
                 .when(F.dayofmonth(F.col("Date")).isin([3,23]),    "rd")
                 .otherwise("th").alias("DaySuffix"),
                F.dayofweek(F.col("Date")).cast("short").alias("Weekday"),
                F.date_format(F.col("Date"), "EEEE").alias("WeekDayName"),
                F.when(F.dayofweek(F.col("Date")).isin([1,7]), True)
                 .otherwise(False).alias("IsWeekend"),
                F.lit(False).alias("IsHoliday"),
                F.lit(None).cast("string").alias("HolidayText"),
                F.lit(None).cast("short").alias("DOWInMonth"),
                F.dayofyear(F.col("Date")).cast("short").alias("DayOfYear"),
                F.lit(None).cast("short").alias("WeekOfMonth"),
                F.weekofyear(F.col("Date")).cast("short").alias("WeekOfYear"),
                F.weekofyear(F.col("Date")).cast("short").alias("ISOWeekOfYear"),
                F.month(F.col("Date")).cast("short").alias("Month"),
                F.date_format(F.col("Date"), "MMMM").alias("MonthName"),
                F.quarter(F.col("Date")).cast("short").alias("Quarter"),
                F.when(F.quarter(F.col("Date")) == 1, "Q1")
                 .when(F.quarter(F.col("Date")) == 2, "Q2")
                 .when(F.quarter(F.col("Date")) == 3, "Q3")
                 .otherwise("Q4").alias("QuarterName"),
                F.year(F.col("Date")).alias("Year"),
                F.date_format(F.col("Date"), "MMyyyy").alias("MMYYYY"),
                F.date_format(F.col("Date"), "MMM-yyyy").alias("MonthYear"),
                F.trunc(F.col("Date"), "month").alias("FirstDayOfMonth"),
                F.last_day(F.col("Date")).alias("LastDayOfMonth"),
                F.trunc(F.col("Date"), "quarter").alias("FirstDayOfQuarter"),
                F.lit(None).cast("date").alias("LastDayOfQuarter"),
                F.trunc(F.col("Date"), "year").alias("FirstDayOfYear"),
                F.lit(None).cast("date").alias("LastDayOfYear"),
                F.lit(None).cast("date").alias("FirstDayOfNextMonth"),
                F.lit(None).cast("date").alias("FirstDayOfNextYear"),
            )
        )

        print(f"DateDimension rows: {dd_conformed.count():,}")
        dd_conformed.show(3, truncate=False)
        write_conformed(dd_conformed, "DateDimension")
    else:
        print("⚠️ No date column found in SCAL_TT_DATE — inspect columns above")
else:
    print("⚠️ SCAL_TT_DATE not available — DateDimension skipped")
```

```python
# ============================================================
# FINAL CELL — Print all 20 SunSystems table dtypes for ASA SQL
# ============================================================
ss_tables = {
    "Analysis_Code_Extensions" : ("Business_Unit", "Analysis_Code"),
    "Analysis_Codes"           : ("Business_Unit", "Analysis_Code"),
    "Analysis_Dimension_Names" : ("Business_Unit", "Analysis_Dimension_Id"),
    "Analysis_Structures"      : ("Business_Unit", "Analysis_Entity_Id"),
    "Analysis_Sub_Dimensions"  : ("Business_Unit", "Analysis_Subdimension_Code"),
    "Budget_Definitions"       : ("Business_Unit", "Budget_Code"),
    "Business_Unit_Addresses"  : ("Business_Unit", "Address_Code"),
    "Business_Unit_Details"    : ("Business_Unit", None),
    "Business_Units"           : ("Business_Unit", None),
    "Chart_Of_Accounts"        : ("Business_Unit", "Account_Code"),
    "Currencies"               : ("Business_Unit", "Currency_Code"),
    "Currency_Rate_Types"      : ("Business_Unit", "Currency_Rate_Type"),
    "DateDimension"            : ("Date",           None),
    "Employee_Roles"           : ("Business_Unit", "Employee_Code"),
    "Fixed_Assets"             : ("Business_Unit", "Asset_Code"),
    "Journal_Definitions"      : ("Business_Unit", "Journal_Type"),
    "Ledger_Lines"             : ("Business_Unit", "Journal_Number"),
    "Ledger_Setups"            : ("Business_Unit", "Ledger_Definition_Id"),
    "Supplier_Region"          : ("Region",         None),
    "Suppliers"                : ("Business_Unit", "Supplier_Code"),
}

def to_asa(spark_type):
    t = spark_type.lower()
    if t == "string":          return "NVARCHAR(255)"
    if t == "date":            return "DATE"
    if t == "timestamp":       return "DATETIME2"
    if t in ("integer","int"): return "INT"
    if t == "long":            return "BIGINT"
    if t in ("double","float"):return "DECIMAL(18,4)"
    if "decimal" in t:         return t.replace("decimaltype(","DECIMAL(").upper()
    if t == "boolean":         return "NVARCHAR(5)"
    if t in ("short","byte","tinyint","smallint"): return "SMALLINT"
    return "NVARCHAR(255)"

for tname, (key1, key2) in ss_tables.items():
    path = f"{conformed_path}/{tname}"
    try:
        df = spark.read.option("recursiveFileLookup","true").parquet(path)
        print(f"\n-- ============================================================")
        print(f"-- {tname}")
        print(f"-- ============================================================")
        print(f"-- Rows: {df.count():,}  |  Columns: {len(df.dtypes)}")
        print(f"CREATE TABLE [zzSTG_offshore_sunsystems].[{tname}]")
        print("(")
        for i, (col, typ) in enumerate(df.dtypes):
            asa   = to_asa(typ)
            comma = "," if i < len(df.dtypes) - 1 else ""
            print(f"    [{col}]{' ' * max(1, 44-len(col))}{asa:<25} NULL{comma}")
        print(")")
        print("WITH (DISTRIBUTION = ROUND_ROBIN, HEAP);")
    except Exception as e:
        print(f"\n-- ⚠️  {tname}: {e}")
```