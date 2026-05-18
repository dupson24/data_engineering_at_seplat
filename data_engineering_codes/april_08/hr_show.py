# ============================================================
# HR Bronze → Silver → Conformed
# PA0002 + PA0105 → EAM.Employee_Details
# ============================================================

raw_path       = "/mnt/sap-ecc-datasphere/sap-ecc-raw/hr"
curated_path   = "/mnt/sap-ecc-datasphere/sap-ecc-curated/hr"
conformed_path = "/mnt/sap-ecc-datasphere/sap-ecc-conformed/eam"

# ============================================================
# STEP 1 — Read raw initial loads (Bronze)
# ============================================================
pa0002 = spark.read.option("recursiveFileLookup", "true").parquet(f"{raw_path}/PA0002/initial")
pa0105 = spark.read.option("recursiveFileLookup", "true").parquet(f"{raw_path}/PA0105/initial")

print(f"PA0002 rows: {pa0002.count():,}  cols: {len(pa0002.columns)}")
print(f"PA0105 rows: {pa0105.count():,}  cols: {len(pa0105.columns)}")

pa0002.show(5, truncate=False)
pa0105.show(5, truncate=False)

# ============================================================
# STEP 3 — Silver: cleanse PA0002 and PA0105
# ============================================================
from pyspark.sql import functions as F

# Cleanse PA0002 — personal data
pa0002_clean = (pa0002
    .filter(F.col("MANDT") == "010")
    .select(
        F.col("PERNR"),
        F.col("VORNA"),       # First name
        F.col("NACHN"),       # Last name
        F.col("GBDAT"),       # Date of birth
        F.col("MOLGA"),       # Country grouping
        # These come from PA0001 — may be NULL if PA0001 missing
        # Include only if present in PA0002 schema
        *[F.col(c) for c in ["PLANS","KOSTL","ORGEH","WERKS","BEGDA","ANSAL","USRID_LONG"]
          if c in pa0002.columns]
    )
    .dropDuplicates(["PERNR"])
)

# Cleanse PA0105 — communication infotype
# Filter SUBTY 0010 = email only
pa0105_clean = (pa0105
    .filter(F.col("MANDT") == "100")
    .filter(F.col("SUBTY") == "0010")   # 0010 = email subtype
    .select(
        F.col("PERNR"),
        F.col("USRID").alias("SMTP_ADDR")   # email stored in USRID on PA0105
    )
    .dropDuplicates(["PERNR"])
)

print(f"PA0002 clean rows: {pa0002_clean.count():,}")
print(f"PA0105 clean rows: {pa0105_clean.count():,}")

# ============================================================
# STEP 4 — Join PA0002 + PA0105 on PERNR
# ============================================================
silver_df = pa0002_clean.join(pa0105_clean, on="PERNR", how="left")

print(f"Silver joined rows: {silver_df.count():,}")
silver_df.show(5, truncate=False)

# ============================================================
# STEP 5 — Write Silver to curated zone
# ============================================================
(silver_df.write
    .mode("overwrite")
    .format("delta")
    .save(f"{curated_path}/employee_details"))

print("✅ Silver written to sap-ecc-curated/hr/employee_details")

# ============================================================
# STEP 6 — Conformed: map to EAM.Employee_Details schema
# ============================================================

def col_if_exists(df, col_name, alias, default=None, cast=None):
    """Return column if exists in df, else return NULL literal."""
    if col_name in df.columns:
        c = F.col(col_name)
        if cast:
            c = c.cast(cast)
        return c.alias(alias)
    else:
        dtype = cast if cast else "string"
        return F.lit(default).cast(dtype).alias(alias)

conformed_df = (silver_df
    .select(
        # Employee_Code — PERNR as string
        F.col("PERNR").alias("Employee_Code"),

        # Employee_Description — concat first + last name
        F.concat_ws(" ",
            F.col("VORNA"),
            F.col("NACHN")
        ).alias("Employee_Description"),

        # Employee_Job_Title — Position code
        col_if_exists(silver_df, "PLANS", "Employee_Job_Title"),

        # Employee_Costcode — Cost centre
        col_if_exists(silver_df, "KOSTL", "Employee_Costcode"),

        # Employee_Organization_Code — Org unit, fall back to WERKS
        F.coalesce(
            F.col("ORGEH") if "ORGEH" in silver_df.columns else F.lit(None),
            F.col("WERKS") if "WERKS" in silver_df.columns else F.lit(None)
        ).alias("Employee_Organization_Code"),

        # Employee_Hire_Date — Start date
        F.to_date(
            F.col("BEGDA"), "yyyyMMdd"
        ).alias("Employee_Hire_Date")
        if "BEGDA" in silver_df.columns
        else F.lit(None).cast("date").alias("Employee_Hire_Date"),

        # Employee_Birthdate — Date of birth
        F.to_date(
            F.col("GBDAT"), "yyyyMMdd"
        ).alias("Employee_Birthdate"),

        # Employee_Payroll_Number — Annual salary as payroll reference
        col_if_exists(silver_df, "ANSAL", "Employee_Payroll_Number", cast="string"),

        # Employee_User — Long user ID
        col_if_exists(silver_df, "USRID_LONG", "Employee_User"),

        # Employee_Email_Address — from PA0105
        F.col("SMTP_ADDR").alias("Employee_Email_Address"),

        # Employee_Country — Country grouping
        F.col("MOLGA").alias("Employee_Country"),
    )
    .filter(F.col("Employee_Code").isNotNull())
)

print(f"Conformed rows: {conformed_df.count():,}")
conformed_df.show(10, truncate=False)

# ============================================================
# STEP 7 — Write conformed to sap-ecc-conformed/eam/employee_details
# ============================================================
(conformed_df.write
    .mode("overwrite")
    .format("delta")
    .save(f"{conformed_path}/employee_details"))

print("✅ Conformed written to sap-ecc-conformed/eam/employee_details")

# ============================================================
# STEP 8 — Data quality report
# ============================================================
total         = conformed_df.count()
null_code     = conformed_df.filter(F.col("Employee_Code").isNull()).count()
null_email    = conformed_df.filter(F.col("Employee_Email_Address").isNull()).count()
null_org      = conformed_df.filter(F.col("Employee_Organization_Code").isNull()).count()
null_hiredate = conformed_df.filter(F.col("Employee_Hire_Date").isNull()).count()

print(f"""
{'='*55}
EAM.Employee_Details — Quality Report
{'='*55}
Total rows                    : {total:,}
Null Employee_Code            : {null_code:,}
Null Employee_Email_Address   : {null_email:,}  ← PA0105 unmatched
Null Employee_Organization_Code: {null_org:,}  ← PA0001 missing
Null Employee_Hire_Date       : {null_hiredate:,}  ← PA0001 missing
{'='*55}
""")