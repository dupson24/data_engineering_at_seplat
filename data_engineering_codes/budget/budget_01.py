# ============================================================
# Sunsystems.Budgets — FROM SCRATCH
# RAW -> CURATED (Silver) -> CONFORMED (Final)
# Tables:
#   PRPS, AUFK  — raw/master-data
#   IMPR        — raw/co-budget
# ============================================================

from pyspark.sql import functions as F

raw_base       = "/mnt/sap-ecc-datasphere/sap-ecc-raw"
master_path    = f"{raw_base}/master-data"
co_path        = f"{raw_base}/co-budget"

curated_path   = "/mnt/sap-ecc-datasphere/sap-ecc-curated/sunsystems"
conformed_path = "/mnt/sap-ecc-datasphere/sap-ecc-conformed/sunsystems"

MANDT = "010"

# ============================================================
# UTILITY (same signature style)
# ============================================================

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
            return initial.unionByName(delta, allowMissingColumns=True)
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

def write_curated(df, target_name):
    (df.write.mode("overwrite")
       .format("parquet")
       .option("compression", "snappy")
       .save(f"{curated_path}/{target_name}"))
    print(f"✅ CURATED {target_name}: {df.count():,} rows written")

def write_conformed(df, target_name):
    spark.conf.set("spark.databricks.delta.formatCheck.enabled", "false")
    (df.write.mode("overwrite").format("parquet")
       .option("compression", "snappy")
       .save(f"{conformed_path}/{target_name}"))
    spark.conf.set("spark.databricks.delta.formatCheck.enabled", "true")
    print(f"✅ CONFORMED {target_name}: {df.count():,} rows written")


# ============================================================
# STEP 1A — PRPS -> CURATED
# (Fix: no KOKRS, use FKOKR/PKOKR/AKOKR fallback)
# ============================================================

prps = safe_read(master_path, "PRPS")

if prps is not None:
    prps_curated = (prps
        .filter(F.col("MANDT") == MANDT) if "MANDT" in prps.columns else prps
        .dropDuplicates(["PSPNR"]) if "PSPNR" in prps.columns else prps
        .select(
            # Business Unit (Controlling Area) — safe coalesce across available columns
            F.coalesce(
                F.col("KOKRS") if "KOKRS" in prps.columns else F.lit(None).cast("string"),
                F.col("FKOKR") if "FKOKR" in prps.columns else F.lit(None).cast("string"),
                F.col("PKOKR") if "PKOKR" in prps.columns else F.lit(None).cast("string"),
                F.col("AKOKR") if "AKOKR" in prps.columns else F.lit(None).cast("string")
            ).alias("Business_Unit"),

            # Keys
            F.col("PSPNR").alias("WBS_Internal_Id") if "PSPNR" in prps.columns else F.lit(None).cast("string").alias("WBS_Internal_Id"),
            F.col("POSID").alias("WBS_Element")    if "POSID" in prps.columns else F.lit(None).cast("string").alias("WBS_Element"),
            F.col("OBJNR").alias("Object_Number")  if "OBJNR" in prps.columns else F.lit(None).cast("string").alias("Object_Number"),
            F.col("PSPHI").alias("WBS_Parent_Id")  if "PSPHI" in prps.columns else F.lit(None).cast("string").alias("WBS_Parent_Id"),

            # Company Code — PRPS extract may carry ABUKR / PBUKR rather than BUKRS
            F.coalesce(
                F.col("BUKRS") if "BUKRS" in prps.columns else F.lit(None).cast("string"),
                F.col("ABUKR") if "ABUKR" in prps.columns else F.lit(None).cast("string"),
                F.col("PBUKR") if "PBUKR" in prps.columns else F.lit(None).cast("string")
            ).alias("Company_Code"),

            # Org/CO assignments
            F.col("WERKS").alias("Plant")          if "WERKS" in prps.columns else F.lit(None).cast("string").alias("Plant"),
            F.col("KOSTL").alias("Cost_Centre")    if "KOSTL" in prps.columns else F.lit(None).cast("string").alias("Cost_Centre"),
            F.col("PRCTR").alias("Profit_Centre")  if "PRCTR" in prps.columns else F.lit(None).cast("string").alias("Profit_Centre"),
            F.col("FKBER").alias("Functional_Area")if "FKBER" in prps.columns else F.lit(None).cast("string").alias("Functional_Area"),

            # Descriptions
            F.col("POST1").alias("WBS_Description") if "POST1" in prps.columns else F.lit(None).cast("string").alias("WBS_Description"),
            F.col("POSTU").alias("WBS_Description_2") if "POSTU" in prps.columns else F.lit(None).cast("string").alias("WBS_Description_2"),

            # Validity / dates
            F.col("DATAB").alias("Valid_From") if "DATAB" in prps.columns else F.lit(None).cast("string").alias("Valid_From"),
            F.col("DATBI").alias("Valid_Until") if "DATBI" in prps.columns else F.lit(None).cast("string").alias("Valid_Until"),
            F.col("ERDAT").alias("Created") if "ERDAT" in prps.columns else (F.col("ERSDA").alias("Created") if "ERSDA" in prps.columns else F.lit(None).cast("string").alias("Created")),
            F.col("ERNAM").alias("Created_By") if "ERNAM" in prps.columns else F.lit(None).cast("string").alias("Created_By"),
            F.col("AEDAT").alias("Last_Updated") if "AEDAT" in prps.columns else F.lit(None).cast("string").alias("Last_Updated"),
            F.col("AENAM").alias("Last_Updated_By") if "AENAM" in prps.columns else F.lit(None).cast("string").alias("Last_Updated_By"),

            # Status / deletion
            F.col("LOEVM").alias("Deletion_Indicator") if "LOEVM" in prps.columns else F.lit(None).cast("string").alias("Deletion_Indicator"),

            # Z fields you already care about
            F.col("ZZPPSA").alias("ZZPPSA") if "ZZPPSA" in prps.columns else F.lit(None).cast("string").alias("ZZPPSA"),
            F.col("ZZNODC").alias("ZZNODC") if "ZZNODC" in prps.columns else F.lit(None).cast("string").alias("ZZNODC"),
            F.col("ZZOLDNR").alias("ZZOLDNR") if "ZZOLDNR" in prps.columns else F.lit(None).cast("string").alias("ZZOLDNR"),
            F.col("ZZPRZ01").alias("ZZPRZ01") if "ZZPRZ01" in prps.columns else F.lit(None).cast("string").alias("ZZPRZ01"),
            F.col("ZZPRZ02").alias("ZZPRZ02") if "ZZPRZ02" in prps.columns else F.lit(None).cast("string").alias("ZZPRZ02"),
        )
        .filter(F.col("WBS_Element").isNotNull())
    )

    print(f"PRPS curated rows: {prps_curated.count():,}")
    prps_curated.show(3, truncate=False)
    write_curated(prps_curated, "PRPS")

else:
    print("⚠️ PRPS not available — PRPS curated skipped")


# ============================================================
# STEP 1B — AUFK -> CURATED
# ============================================================

aufk = safe_read(master_path, "AUFK")

if aufk is not None:
    aufk_curated = (aufk
        .filter(F.col("MANDT") == MANDT) if "MANDT" in aufk.columns else aufk
        .dropDuplicates(["AUFNR"]) if "AUFNR" in aufk.columns else aufk
        .select(
            # Business Unit (Controlling Area) — use KOKRS if present else fallbacks if any exist
            F.coalesce(
                F.col("KOKRS") if "KOKRS" in aufk.columns else F.lit(None).cast("string"),
                F.col("FKOKR") if "FKOKR" in aufk.columns else F.lit(None).cast("string"),
                F.col("PKOKR") if "PKOKR" in aufk.columns else F.lit(None).cast("string"),
                F.col("AKOKR") if "AKOKR" in aufk.columns else F.lit(None).cast("string")
            ).alias("Business_Unit"),

            F.col("AUFNR").alias("Internal_Order") if "AUFNR" in aufk.columns else F.lit(None).cast("string").alias("Internal_Order"),
            F.col("OBJNR").alias("Object_Number")  if "OBJNR" in aufk.columns else F.lit(None).cast("string").alias("Object_Number"),

            F.col("AUART").alias("Order_Type")     if "AUART" in aufk.columns else F.lit(None).cast("string").alias("Order_Type"),
            F.col("AUTYP").alias("Order_Category") if "AUTYP" in aufk.columns else F.lit(None).cast("string").alias("Order_Category"),

            F.coalesce(
                F.col("BUKRS") if "BUKRS" in aufk.columns else F.lit(None).cast("string"),
                F.col("ABUKR") if "ABUKR" in aufk.columns else F.lit(None).cast("string")
            ).alias("Company_Code"),

            F.col("WERKS").alias("Plant") if "WERKS" in aufk.columns else F.lit(None).cast("string").alias("Plant"),
            F.col("KOSTV").alias("Responsible_Cost_Centre") if "KOSTV" in aufk.columns else F.lit(None).cast("string").alias("Responsible_Cost_Centre"),
            F.col("KOSTL").alias("Assigned_Cost_Centre")    if "KOSTL" in aufk.columns else F.lit(None).cast("string").alias("Assigned_Cost_Centre"),
            F.col("PRCTR").alias("Profit_Centre")           if "PRCTR" in aufk.columns else F.lit(None).cast("string").alias("Profit_Centre"),
            F.col("FKBER").alias("Functional_Area")         if "FKBER" in aufk.columns else F.lit(None).cast("string").alias("Functional_Area"),

            (F.col("KTEXT").alias("Order_Description") if "KTEXT" in aufk.columns else
             (F.col("LTXA1").alias("Order_Description") if "LTXA1" in aufk.columns else F.lit(None).cast("string").alias("Order_Description"))),

            F.col("ERDAT").alias("Created") if "ERDAT" in aufk.columns else F.lit(None).cast("string").alias("Created"),
            F.col("ERNAM").alias("Created_By") if "ERNAM" in aufk.columns else F.lit(None).cast("string").alias("Created_By"),
            F.col("AEDAT").alias("Last_Updated") if "AEDAT" in aufk.columns else F.lit(None).cast("string").alias("Last_Updated"),
            F.col("AENAM").alias("Last_Updated_By") if "AENAM" in aufk.columns else F.lit(None).cast("string").alias("Last_Updated_By"),

            F.col("LOEVM").alias("Deletion_Indicator") if "LOEVM" in aufk.columns else F.lit(None).cast("string").alias("Deletion_Indicator")
        )
        .filter(F.col("Internal_Order").isNotNull())
    )

    print(f"AUFK curated rows: {aufk_curated.count():,}")
    aufk_curated.show(3, truncate=False)
    write_curated(aufk_curated, "AUFK")

else:
    print("⚠️ AUFK not available — AUFK curated skipped")


# ============================================================
# STEP 1C — IMPR -> CURATED
# ============================================================

impr = safe_read(co_path, "IMPR")

if impr is not None:
    impr_curated = (impr
        .filter(F.col("MANDT") == MANDT) if "MANDT" in impr.columns else impr
        .dropDuplicates(["IMPRF","POSNR"]) if ("IMPRF" in impr.columns and "POSNR" in impr.columns) else impr
        .select(
            F.coalesce(
                F.col("KOKRS") if "KOKRS" in impr.columns else F.lit(None).cast("string"),
                F.col("FKOKR") if "FKOKR" in impr.columns else F.lit(None).cast("string"),
                F.col("PKOKR") if "PKOKR" in impr.columns else F.lit(None).cast("string"),
                F.col("AKOKR") if "AKOKR" in impr.columns else F.lit(None).cast("string")
            ).alias("Business_Unit"),

            F.col("IMPRF").alias("Investment_Position_Id") if "IMPRF" in impr.columns else F.lit(None).cast("string").alias("Investment_Position_Id"),
            F.col("POSNR").alias("Investment_Position_Number") if "POSNR" in impr.columns else F.lit(None).cast("string").alias("Investment_Position_Number"),
            F.col("OBJNR").alias("Object_Number") if "OBJNR" in impr.columns else F.lit(None).cast("string").alias("Object_Number"),
            F.col("PSPNR").alias("WBS_Internal_Id") if "PSPNR" in impr.columns else F.lit(None).cast("string").alias("WBS_Internal_Id"),

            F.coalesce(
                F.col("BUKRS") if "BUKRS" in impr.columns else F.lit(None).cast("string"),
                F.col("ABUKR") if "ABUKR" in impr.columns else F.lit(None).cast("string"),
                F.col("PBUKR") if "PBUKR" in impr.columns else F.lit(None).cast("string")
            ).alias("Company_Code"),

            F.col("WERKS").alias("Plant") if "WERKS" in impr.columns else F.lit(None).cast("string").alias("Plant"),
            F.col("KOSTL").alias("Cost_Centre") if "KOSTL" in impr.columns else F.lit(None).cast("string").alias("Cost_Centre"),
            F.col("PRCTR").alias("Profit_Centre") if "PRCTR" in impr.columns else F.lit(None).cast("string").alias("Profit_Centre"),
            F.col("FKBER").alias("Functional_Area") if "FKBER" in impr.columns else F.lit(None).cast("string").alias("Functional_Area"),

            (F.col("BEZEI").alias("Description") if "BEZEI" in impr.columns else
             (F.col("TEXT").alias("Description") if "TEXT" in impr.columns else
              (F.col("TXTSP").alias("Description") if "TXTSP" in impr.columns else F.lit(None).cast("string").alias("Description")))),

            F.col("DATAB").alias("Valid_From") if "DATAB" in impr.columns else F.lit(None).cast("string").alias("Valid_From"),
            F.col("DATBI").alias("Valid_Until") if "DATBI" in impr.columns else F.lit(None).cast("string").alias("Valid_Until"),

            F.col("ERDAT").alias("Created") if "ERDAT" in impr.columns else (F.col("ERSDA").alias("Created") if "ERSDA" in impr.columns else F.lit(None).cast("string").alias("Created")),
            F.col("ERNAM").alias("Created_By") if "ERNAM" in impr.columns else F.lit(None).cast("string").alias("Created_By"),
            F.col("AEDAT").alias("Last_Updated") if "AEDAT" in impr.columns else F.lit(None).cast("string").alias("Last_Updated"),
            F.col("AENAM").alias("Last_Updated_By") if "AENAM" in impr.columns else F.lit(None).cast("string").alias("Last_Updated_By"),

            F.col("LOEVM").alias("Deletion_Indicator") if "LOEVM" in impr.columns else F.lit(None).cast("string").alias("Deletion_Indicator")
        )
        .filter(F.col("Investment_Position_Id").isNotNull())
    )

    print(f"IMPR curated rows: {impr_curated.count():,}")
    impr_curated.show(3, truncate=False)
    write_curated(impr_curated, "IMPR")

else:
    print("⚠️ IMPR not available — IMPR curated skipped")


# ============================================================
# STEP 2 — CURATED -> CONFORMED (Final)
# ============================================================

def read_curated(table_name):
    try:
        df = spark.read.option("mergeSchema", "true").parquet(f"{curated_path}/{table_name}")
        print(f"{table_name} curated read: {df.count():,} rows")
        return df
    except Exception as e:
        print(f"⚠️ {table_name} curated read failed: {e}")
        return None

prps_c = read_curated("PRPS")
if prps_c is not None:
    print(f"PRPS conformed rows: {prps_c.count():,}")
    prps_c.show(3, truncate=False)
    write_conformed(prps_c, "PRPS_WBS_Elements")

aufk_c = read_curated("AUFK")
if aufk_c is not None:
    print(f"AUFK conformed rows: {aufk_c.count():,}")
    aufk_c.show(3, truncate=False)
    write_conformed(aufk_c, "AUFK_Internal_Orders")

impr_c = read_curated("IMPR")
if impr_c is not None:
    print(f"IMPR conformed rows: {impr_c.count():,}")
    impr_c.show(3, truncate=False)
    write_conformed(impr_c, "IMPR_Investment_Program_Positions")

print("\n✅ DONE: RAW -> CURATED -> CONFORMED pipeline complete.")