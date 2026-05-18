# ============================================================
# Sunsystems.Budgets — Curated(Silver) -> Conformed
# PRPS, AUFK — folder: curated (silver)
# IMPR       — folder: curated (silver)
# ============================================================

from pyspark.sql import functions as F

raw_base        = "/mnt/sap-ecc-datasphere/sap-ecc-raw"
master_path     = f"{raw_base}/master-data"
co_path         = f"{raw_base}/co-budget"

curated_path    = "/mnt/sap-ecc-datasphere/sap-ecc-curated/sunsystems"     # ✅ Silver
conformed_path  = "/mnt/sap-ecc-datasphere/sap-ecc-conformed/sunsystems"   # ✅ Conformed

MANDT = "010"

# ============================================================
# UTILITY GUARD (NO ERRORS) — only defines if missing
# Keeps EXACT signature: safe_read(folder_path, table_name), write_conformed(df, target_name)
# Also supports curated being either {table}/initial|delta OR just {table}
# ============================================================

try:
    safe_read
    write_conformed
except NameError:
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
            # If curated has initial/delta structure
            try:
                _ = dbutils.fs.ls(f"{folder_path}/{table_name}/initial")
                return read_table(folder_path, table_name)
            except:
                # Else curated is flat: {folder}/{table}
                _ = dbutils.fs.ls(f"{folder_path}/{table_name}")
                df = (spark.read
                    .option("recursiveFileLookup", "true")
                    .option("mergeSchema", "true")
                    .parquet(f"{folder_path}/{table_name}"))
                print(f"{table_name} curated(flat): {df.count():,} rows")
                return df
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

# ============================================================
# STEP 1 — PRPS_WBS_Elements
# Primary: PRPS (WBS Elements)
# Purpose: WBS + controlling assignments used in budget/spend analysis
# ============================================================

prps = safe_read(curated_path, "PRPS")

if prps:
    prps_conformed = (prps
        .filter(F.col("MANDT") == MANDT) if "MANDT" in prps.columns else prps
        .dropDuplicates(["PSPNR"]) if "PSPNR" in prps.columns else prps
        .select(
            # Keys
            (F.col("KOKRS").alias("Business_Unit") if "KOKRS" in prps.columns else F.lit(None).cast("string").alias("Business_Unit")),
            (F.col("PSPNR").alias("WBS_Internal_Id") if "PSPNR" in prps.columns else F.lit(None).cast("string").alias("WBS_Internal_Id")),
            (F.col("POSID").alias("WBS_Element") if "POSID" in prps.columns else F.lit(None).cast("string").alias("WBS_Element")),
            (F.col("OBJNR").alias("Object_Number") if "OBJNR" in prps.columns else F.lit(None).cast("string").alias("Object_Number")),

            # Organisational / controlling
            (F.col("BUKRS").alias("Company_Code") if "BUKRS" in prps.columns else F.lit(None).cast("string").alias("Company_Code")),
            (F.col("WERKS").alias("Plant") if "WERKS" in prps.columns else F.lit(None).cast("string").alias("Plant")),
            (F.col("KOSTL").alias("Cost_Centre") if "KOSTL" in prps.columns else F.lit(None).cast("string").alias("Cost_Centre")),
            (F.col("PRCTR").alias("Profit_Centre") if "PRCTR" in prps.columns else F.lit(None).cast("string").alias("Profit_Centre")),
            (F.col("FKBER").alias("Functional_Area") if "FKBER" in prps.columns else F.lit(None).cast("string").alias("Functional_Area")),

            # Description / text
            (F.col("POST1").alias("WBS_Description") if "POST1" in prps.columns else F.lit(None).cast("string").alias("WBS_Description")),
            (F.col("POSTU").alias("WBS_Description_2") if "POSTU" in prps.columns else F.lit(None).cast("string").alias("WBS_Description_2")),

            # Dates / validity (SAP dates may be yyyyMMdd; keep raw, or parse later if needed)
            (F.col("PSTRT").alias("Start_Date") if "PSTRT" in prps.columns else F.lit(None).cast("string").alias("Start_Date")),
            (F.col("PENDE").alias("End_Date") if "PENDE" in prps.columns else F.lit(None).cast("string").alias("End_Date")),
            (F.col("DATAB").alias("Valid_From") if "DATAB" in prps.columns else F.lit(None).cast("string").alias("Valid_From")),
            (F.col("DATBI").alias("Valid_Until") if "DATBI" in prps.columns else F.lit(None).cast("string").alias("Valid_Until")),

            # Audit
            (F.col("ERSDA").alias("Created") if "ERSDA" in prps.columns else F.lit(None).cast("string").alias("Created")),
            (F.col("ERNAM").alias("Created_By") if "ERNAM" in prps.columns else F.lit(None).cast("string").alias("Created_By")),
            (F.col("AEDAT").alias("Last_Updated") if "AEDAT" in prps.columns else F.lit(None).cast("string").alias("Last_Updated")),
            (F.col("AENAM").alias("Last_Updated_By") if "AENAM" in prps.columns else F.lit(None).cast("string").alias("Last_Updated_By")),

            # Status / deletion indicators (if available)
            (F.col("LOEVM").alias("Deletion_Indicator") if "LOEVM" in prps.columns else
             (F.col("LVORM").alias("Deletion_Indicator") if "LVORM" in prps.columns else F.lit(None).cast("string").alias("Deletion_Indicator"))),

            # Z-fields (budget/spend analysis extensions) — keep only known relevant ones
            (F.col("ZZROYCAT").alias("ZZROYCAT") if "ZZROYCAT" in prps.columns else F.lit(None).cast("string").alias("ZZROYCAT")),
            (F.col("ZZPSEC").alias("ZZPSEC") if "ZZPSEC" in prps.columns else F.lit(None).cast("string").alias("ZZPSEC")),
            (F.col("ZZPSTRU").alias("ZZPSTRU") if "ZZPSTRU" in prps.columns else F.lit(None).cast("string").alias("ZZPSTRU")),
            (F.col("ZZPPSA").alias("ZZPPSA") if "ZZPPSA" in prps.columns else F.lit(None).cast("string").alias("ZZPPSA")),
        )
        .filter(F.col("WBS_Element").isNotNull())
    )

    print(f"PRPS_WBS_Elements rows: {prps_conformed.count():,}")
    prps_conformed.show(3, truncate=False)
    write_conformed(prps_conformed, "PRPS_WBS_Elements")

else:
    print("⚠️ PRPS not available — PRPS_WBS_Elements skipped")


# ============================================================
# STEP 2 — AUFK_Internal_Orders
# Primary: AUFK (Internal Orders master)
# Purpose: Internal Order + controlling assignments used in budget/spend analysis
# ============================================================

aufk = safe_read(curated_path, "AUFK")

if aufk:
    aufk_conformed = (aufk
        .filter(F.col("MANDT") == MANDT) if "MANDT" in aufk.columns else aufk
        .dropDuplicates(["AUFNR"]) if "AUFNR" in aufk.columns else aufk
        .select(
            # Keys
            (F.col("KOKRS").alias("Business_Unit") if "KOKRS" in aufk.columns else F.lit(None).cast("string").alias("Business_Unit")),
            (F.col("AUFNR").alias("Internal_Order") if "AUFNR" in aufk.columns else F.lit(None).cast("string").alias("Internal_Order")),
            (F.col("OBJNR").alias("Object_Number") if "OBJNR" in aufk.columns else F.lit(None).cast("string").alias("Object_Number")),

            # Classification
            (F.col("AUART").alias("Order_Type") if "AUART" in aufk.columns else F.lit(None).cast("string").alias("Order_Type")),
            (F.col("AUTYP").alias("Order_Category") if "AUTYP" in aufk.columns else F.lit(None).cast("string").alias("Order_Category")),

            # Organisational / controlling
            (F.col("BUKRS").alias("Company_Code") if "BUKRS" in aufk.columns else F.lit(None).cast("string").alias("Company_Code")),
            (F.col("WERKS").alias("Plant") if "WERKS" in aufk.columns else F.lit(None).cast("string").alias("Plant")),
            (F.col("KOSTV").alias("Responsible_Cost_Centre") if "KOSTV" in aufk.columns else F.lit(None).cast("string").alias("Responsible_Cost_Centre")),
            (F.col("KOSTL").alias("Assigned_Cost_Centre") if "KOSTL" in aufk.columns else F.lit(None).cast("string").alias("Assigned_Cost_Centre")),
            (F.col("PRCTR").alias("Profit_Centre") if "PRCTR" in aufk.columns else F.lit(None).cast("string").alias("Profit_Centre")),
            (F.col("FKBER").alias("Functional_Area") if "FKBER" in aufk.columns else F.lit(None).cast("string").alias("Functional_Area")),

            # Description / text
            (F.col("KTEXT").alias("Order_Description") if "KTEXT" in aufk.columns else
             (F.col("LTXA1").alias("Order_Description") if "LTXA1" in aufk.columns else F.lit(None).cast("string").alias("Order_Description"))),

            # Dates
            (F.col("ERDAT").alias("Created") if "ERDAT" in aufk.columns else F.lit(None).cast("string").alias("Created")),
            (F.col("ERNAM").alias("Created_By") if "ERNAM" in aufk.columns else F.lit(None).cast("string").alias("Created_By")),
            (F.col("AEDAT").alias("Last_Updated") if "AEDAT" in aufk.columns else F.lit(None).cast("string").alias("Last_Updated")),
            (F.col("AENAM").alias("Last_Updated_By") if "AENAM" in aufk.columns else F.lit(None).cast("string").alias("Last_Updated_By")),
            (F.col("GSTRP").alias("Start_Date") if "GSTRP" in aufk.columns else F.lit(None).cast("string").alias("Start_Date")),
            (F.col("GLTRP").alias("End_Date") if "GLTRP" in aufk.columns else F.lit(None).cast("string").alias("End_Date")),

            # Status / deletion indicators
            (F.col("LOEVM").alias("Deletion_Indicator") if "LOEVM" in aufk.columns else
             (F.col("LVORM").alias("Deletion_Indicator") if "LVORM" in aufk.columns else F.lit(None).cast("string").alias("Deletion_Indicator"))),

            # Z-fields (keep only if present)
            (F.col("ZZROYCAT").alias("ZZROYCAT") if "ZZROYCAT" in aufk.columns else F.lit(None).cast("string").alias("ZZROYCAT")),
            (F.col("ZZPSEC").alias("ZZPSEC") if "ZZPSEC" in aufk.columns else F.lit(None).cast("string").alias("ZZPSEC")),
            (F.col("ZZPSTRU").alias("ZZPSTRU") if "ZZPSTRU" in aufk.columns else F.lit(None).cast("string").alias("ZZPSTRU")),
            (F.col("ZZPPSA").alias("ZZPPSA") if "ZZPPSA" in aufk.columns else F.lit(None).cast("string").alias("ZZPPSA")),
        )
        .filter(F.col("Internal_Order").isNotNull())
    )

    print(f"AUFK_Internal_Orders rows: {aufk_conformed.count():,}")
    aufk_conformed.show(3, truncate=False)
    write_conformed(aufk_conformed, "AUFK_Internal_Orders")

else:
    print("⚠️ AUFK not available — AUFK_Internal_Orders skipped")


# ============================================================
# STEP 3 — IMPR_Investment_Program_Positions
# Primary: IMPR (Investment program positions / budget objects)
# Purpose: Budget structure and hierarchy (often used to hold budget objects)
# ============================================================

impr = safe_read(curated_path, "IMPR")

if impr:
    impr_conformed = (impr
        .filter(F.col("MANDT") == MANDT) if "MANDT" in impr.columns else impr
        .dropDuplicates(["IMPRF","POSNR"]) if ("IMPRF" in impr.columns and "POSNR" in impr.columns) else impr
        .select(
            # Keys
            (F.col("KOKRS").alias("Business_Unit") if "KOKRS" in impr.columns else F.lit(None).cast("string").alias("Business_Unit")),
            (F.col("IMPRF").alias("Investment_Position_Id") if "IMPRF" in impr.columns else F.lit(None).cast("string").alias("Investment_Position_Id")),
            (F.col("POSNR").alias("Investment_Position_Number") if "POSNR" in impr.columns else F.lit(None).cast("string").alias("Investment_Position_Number")),
            (F.col("OBJNR").alias("Object_Number") if "OBJNR" in impr.columns else F.lit(None).cast("string").alias("Object_Number")),
            (F.col("PSPNR").alias("WBS_Internal_Id") if "PSPNR" in impr.columns else F.lit(None).cast("string").alias("WBS_Internal_Id")),

            # Program / hierarchy (names vary across ECC builds — keep only if present)
            (F.col("PROG").alias("Program_Id") if "PROG" in impr.columns else
             (F.col("PROJN").alias("Program_Id") if "PROJN" in impr.columns else F.lit(None).cast("string").alias("Program_Id"))),
            (F.col("PRNAM").alias("Program_Name") if "PRNAM" in impr.columns else F.lit(None).cast("string").alias("Program_Name")),
            (F.col("UPOSNR").alias("Parent_Position_Number") if "UPOSNR" in impr.columns else F.lit(None).cast("string").alias("Parent_Position_Number")),
            (F.col("STUFE").alias("Hierarchy_Level") if "STUFE" in impr.columns else F.lit(None).cast("string").alias("Hierarchy_Level")),

            # Organisational / controlling
            (F.col("BUKRS").alias("Company_Code") if "BUKRS" in impr.columns else F.lit(None).cast("string").alias("Company_Code")),
            (F.col("WERKS").alias("Plant") if "WERKS" in impr.columns else F.lit(None).cast("string").alias("Plant")),
            (F.col("KOSTL").alias("Cost_Centre") if "KOSTL" in impr.columns else F.lit(None).cast("string").alias("Cost_Centre")),
            (F.col("PRCTR").alias("Profit_Centre") if "PRCTR" in impr.columns else F.lit(None).cast("string").alias("Profit_Centre")),
            (F.col("FKBER").alias("Functional_Area") if "FKBER" in impr.columns else F.lit(None).cast("string").alias("Functional_Area")),

            # Text fields (vary — take best available)
            (F.col("BEZEI").alias("Description") if "BEZEI" in impr.columns else
             (F.col("TEXT").alias("Description") if "TEXT" in impr.columns else
              (F.col("TXT").alias("Description") if "TXT" in impr.columns else F.lit(None).cast("string").alias("Description")))),

            # Validity / audit
            (F.col("DATAB").alias("Valid_From") if "DATAB" in impr.columns else F.lit(None).cast("string").alias("Valid_From")),
            (F.col("DATBI").alias("Valid_Until") if "DATBI" in impr.columns else F.lit(None).cast("string").alias("Valid_Until")),
            (F.col("ERSDA").alias("Created") if "ERSDA" in impr.columns else F.lit(None).cast("string").alias("Created")),
            (F.col("ERNAM").alias("Created_By") if "ERNAM" in impr.columns else F.lit(None).cast("string").alias("Created_By")),
            (F.col("AEDAT").alias("Last_Updated") if "AEDAT" in impr.columns else F.lit(None).cast("string").alias("Last_Updated")),
            (F.col("AENAM").alias("Last_Updated_By") if "AENAM" in impr.columns else F.lit(None).cast("string").alias("Last_Updated_By")),

            # Status / deletion indicators
            (F.col("LOEVM").alias("Deletion_Indicator") if "LOEVM" in impr.columns else
             (F.col("LVORM").alias("Deletion_Indicator") if "LVORM" in impr.columns else F.lit(None).cast("string").alias("Deletion_Indicator"))),

            # Z-fields (keep only if present)
            (F.col("ZZROYCAT").alias("ZZROYCAT") if "ZZROYCAT" in impr.columns else F.lit(None).cast("string").alias("ZZROYCAT")),
            (F.col("ZZPSEC").alias("ZZPSEC") if "ZZPSEC" in impr.columns else F.lit(None).cast("string").alias("ZZPSEC")),
            (F.col("ZZPSTRU").alias("ZZPSTRU") if "ZZPSTRU" in impr.columns else F.lit(None).cast("string").alias("ZZPSTRU")),
            (F.col("ZZPPSA").alias("ZZPPSA") if "ZZPPSA" in impr.columns else F.lit(None).cast("string").alias("ZZPPSA")),
        )
        .filter(F.col("Investment_Position_Id").isNotNull())
    )

    print(f"IMPR_Investment_Program_Positions rows: {impr_conformed.count():,}")
    impr_conformed.show(3, truncate=False)
    write_conformed(impr_conformed, "IMPR_Investment_Program_Positions")

else:
    print("⚠️ IMPR not available — IMPR_Investment_Program_Positions skipped")