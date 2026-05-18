```python
# ============================================================
# EAM Part 3 — Remaining Tables
# ============================================================

raw_base       = "/mnt/sap-ecc-datasphere/sap-ecc-raw"
tx_path        = f"{raw_base}/transaction-data"
master_path    = f"{raw_base}/master-data"
ref_path       = f"{raw_base}/reference-and-config"
co_path        = f"{raw_base}/co-budget"
hr_path        = f"{raw_base}/hr"
eam_path       = f"{raw_base}/eam_ecc_raw_tables"   # underscore
eam_path2      = f"{raw_base}/eam-ecc-raw-tables"   # hyphen
pm_path        = f"{raw_base}/pm-asset-events"
curated_path   = "/mnt/sap-ecc-datasphere/sap-ecc-curated/eam"
conformed_path = "/mnt/sap-ecc-datasphere/sap-ecc-conformed/eam"

MANDT = "010"
```

```python
# ============================================================
# UTILITY
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
    try:
        return read_table(folder_path, table_name)
    except Exception as e:
        print(f"⚠️ {table_name} not available at {folder_path}: {e}")
        return None

def write_conformed(df, target_name):
    spark.conf.set("spark.databricks.delta.formatCheck.enabled", "false")
    (df.write.mode("overwrite").format("parquet")
       .option("compression","snappy")
       .save(f"{conformed_path}/{target_name}"))
    spark.conf.set("spark.databricks.delta.formatCheck.enabled", "true")
    print(f"✅ {target_name}: {df.count():,} rows")
```

```python
# ============================================================
# STEP 1 — Quotation_Requests_Parts_Details
# EKAP — folder: eam_ecc_raw_tables
# ============================================================
ekap = safe_read(eam_path, "EKAP")
if ekap: print("\nEKAP columns:", ekap.columns)
```

```python
if ekap:
    # Filter material lines only — PSTYP = 0 (standard procurement)
    if "PSTYP" in ekap.columns:
        print("PSTYP values:", ekap.select("PSTYP").distinct().collect())

    ekap_conformed = (ekap
        .filter(F.col("MANDT") == MANDT)
        .filter(F.col("PSTYP") == "0" if "PSTYP" in ekap.columns else F.lit(True))
        .dropDuplicates(["ANFNR","ANPOS"])
        .select(
            F.col("ANFNR"),      # RFQ number — keep for rename
            F.col("ANPOS"),      # RFQ item — keep for rename
            F.col("MATNR").alias("material_code")
            if "MATNR" in ekap.columns
            else F.lit(None).cast("string").alias("material_code"),
            F.col("TXZ01").alias("item_description")
            if "TXZ01" in ekap.columns
            else F.lit(None).cast("string").alias("item_description"),
            F.col("MENGE").cast("decimal(18,3)").alias("rfq_quantity")
            if "MENGE" in ekap.columns
            else F.lit(None).cast("decimal(18,3)").alias("rfq_quantity"),
            F.col("MEINS").alias("unit_of_measure")
            if "MEINS" in ekap.columns
            else F.lit(None).cast("string").alias("unit_of_measure"),
            F.col("NETPR").cast("decimal(18,2)").alias("net_price")
            if "NETPR" in ekap.columns
            else F.lit(None).cast("decimal(18,2)").alias("net_price"),
            F.col("MATKL").alias("material_group")
            if "MATKL" in ekap.columns
            else F.lit(None).cast("string").alias("material_group"),
            F.col("WERKS").alias("plant")
            if "WERKS" in ekap.columns
            else F.lit(None).cast("string").alias("plant"),
            F.to_date(F.col("EINDT"), "yyyyMMdd").alias("delivery_date")
            if "EINDT" in ekap.columns
            else F.lit(None).cast("date").alias("delivery_date"),
            F.col("EKORG").alias("purchasing_organisation")
            if "EKORG" in ekap.columns
            else F.lit(None).cast("string").alias("purchasing_organisation"),
        )
        .withColumnRenamed("ANFNR", "rfq_number")
        .withColumnRenamed("ANPOS", "rfq_item_number")
        .filter(F.col("rfq_number").isNotNull())
    )

    print(f"Quotation parts rows: {ekap_conformed.count():,}")
    ekap_conformed.show(5, truncate=False)
    write_conformed(ekap_conformed, "quotation_requests_parts_details")
```

```python
# ============================================================
# STEP 2 — Quotation_Requests_Services_Details
# EKPV — folder: eam_ecc_raw_tables
# ============================================================
ekpv = safe_read(eam_path, "EKPV")
if ekpv: print("\nEKPV columns:", ekpv.columns)
```

```python
if ekpv:
    ekpv_conformed = (ekpv
        .filter(F.col("MANDT") == MANDT)
        if "MANDT" in ekpv.columns
        else ekpv
    )
    ekpv_conformed = (ekpv_conformed
        .dropDuplicates(["EBELN","EBELP"])
        .select(
            F.col("EBELN"),      # keep for rename
            F.col("EBELP"),      # keep for rename
            *[F.col(c) for c in ekpv_conformed.columns
              if c not in ["EBELN","EBELP","MANDT",
                           "__timestamp","__operation_type",
                           "__sequence_number"]]
        )
        .withColumnRenamed("EBELN", "rfq_purchase_order_number")
        .withColumnRenamed("EBELP", "rfq_item_number")
        .filter(F.col("rfq_purchase_order_number").isNotNull())
    )

    print(f"Quotation services rows: {ekpv_conformed.count():,}")
    ekpv_conformed.show(5, truncate=False)
    write_conformed(ekpv_conformed, "quotation_requests_services_details")
```

```python
# ============================================================
# STEP 3 — R5Objects_Details
# EQUI + EQKT + ILOA — folder: pm-asset-events
# ============================================================
equi = safe_read(pm_path, "EQUI")
eqkt = safe_read(pm_path, "EQKT")
iloa = safe_read(pm_path, "ILOA")

if equi: print("\nEQUI columns:", equi.columns)
if eqkt: print("EQKT columns:", eqkt.columns)
if iloa: print("ILOA columns:", iloa.columns)
```

```python
if equi:
    equi_clean = (equi
        .filter(F.col("MANDT") == MANDT)
        .dropDuplicates(["EQUNR"])
        .select(
            F.col("EQUNR"),      # keep for joins
            F.col("EQTYP").alias("equipment_category")
            if "EQTYP" in equi.columns
            else F.lit(None).cast("string").alias("equipment_category"),
            F.col("ANLNR").alias("asset_number")
            if "ANLNR" in equi.columns
            else F.lit(None).cast("string").alias("asset_number"),
            F.col("IWERK").alias("maintenance_plant")
            if "IWERK" in equi.columns
            else F.lit(None).cast("string").alias("maintenance_plant"),
            F.col("KOSTL").alias("cost_centre")
            if "KOSTL" in equi.columns
            else F.lit(None).cast("string").alias("cost_centre"),
            F.col("INBDT").cast("string").alias("installation_date")
            if "INBDT" in equi.columns
            else F.lit(None).cast("string").alias("installation_date"),
            F.col("HERST").alias("manufacturer")
            if "HERST" in equi.columns
            else F.lit(None).cast("string").alias("manufacturer"),
            F.col("SERGE").alias("serial_number")
            if "SERGE" in equi.columns
            else F.lit(None).cast("string").alias("serial_number"),
            F.col("MATNR").alias("material_code")
            if "MATNR" in equi.columns
            else F.lit(None).cast("string").alias("material_code"),
            F.col("ISTAT").alias("system_status")
            if "ISTAT" in equi.columns
            else F.lit(None).cast("string").alias("system_status"),
            F.col("WERKS").alias("plant")
            if "WERKS" in equi.columns
            else F.lit(None).cast("string").alias("plant"),
        )
    )

    r5obj_silver = equi_clean

    # Join EQKT — equipment descriptions
    if eqkt:
        eqkt_clean = (eqkt
            .filter(F.col("MANDT") == MANDT)
            .filter(F.col("SPRAS") == "E")
            .dropDuplicates(["EQUNR"])
            .select(
                F.col("EQUNR"),
                F.col("EQKTX").alias("equipment_description"),
            )
        )
        r5obj_silver = r5obj_silver.join(eqkt_clean, on="EQUNR", how="left")

    # Join ILOA — installation location
    if iloa:
        iloa_clean = (iloa
            .filter(F.col("MANDT") == MANDT)
            .dropDuplicates(["EQUNR"])
            .select(
                F.col("EQUNR"),
                F.col("TPLNR").alias("functional_location")
                if "TPLNR" in iloa.columns
                else F.lit(None).cast("string").alias("functional_location"),
                F.col("SWERK").alias("responsible_plant")
                if "SWERK" in iloa.columns
                else F.lit(None).cast("string").alias("responsible_plant"),
                F.col("STORT").alias("location")
                if "STORT" in iloa.columns
                else F.lit(None).cast("string").alias("location"),
                F.col("BEBER").alias("business_area")
                if "BEBER" in iloa.columns
                else F.lit(None).cast("string").alias("business_area"),
            )
        )
        r5obj_silver = r5obj_silver.join(iloa_clean, on="EQUNR", how="left")

    # Rename join key
    r5obj_conformed = (r5obj_silver
        .withColumnRenamed("EQUNR", "equipment_number")
        .filter(F.col("equipment_number").isNotNull())
    )

    print(f"R5Objects rows: {r5obj_conformed.count():,}")
    r5obj_conformed.show(5, truncate=False)
    write_conformed(r5obj_conformed, "r5objects_details")
```

```python
# ============================================================
# STEP 4 — R5Schedgroups_Details
# CRHD + CRCO — folder: eam_ecc_raw_tables
# ============================================================
crhd = safe_read(eam_path, "CRHD")
crco = safe_read(eam_path, "CRCO")

if crhd: print("\nCRHD columns:", crhd.columns)
if crco: print("CRCO columns:", crco.columns)
```

```python
if crhd:
    crhd_clean = (crhd
        .filter(F.col("MANDT") == MANDT)
        .dropDuplicates(["OBJID"])
        .select(
            F.col("OBJID"),      # keep for join
            F.col("ARBPL").alias("work_centre_code")
            if "ARBPL" in crhd.columns
            else F.lit(None).cast("string").alias("work_centre_code"),
            F.col("WERKS").alias("plant")
            if "WERKS" in crhd.columns
            else F.lit(None).cast("string").alias("plant"),
            F.col("VERWE").alias("usage")
            if "VERWE" in crhd.columns
            else F.lit(None).cast("string").alias("usage"),
            F.col("KTEXT").alias("work_centre_description")
            if "KTEXT" in crhd.columns
            else F.lit(None).cast("string").alias("work_centre_description"),
            F.col("VERAN").alias("responsible_person")
            if "VERAN" in crhd.columns
            else F.lit(None).cast("string").alias("responsible_person"),
        )
    )

    schedgroup_silver = crhd_clean

    # Join CRCO — cost centre assignment
    if crco:
        crco_clean = (crco
            .filter(F.col("MANDT") == MANDT)
            .dropDuplicates(["OBJID"])
            .select(
                F.col("OBJID"),
                F.col("KOSTL").alias("cost_centre")
                if "KOSTL" in crco.columns
                else F.lit(None).cast("string").alias("cost_centre"),
                F.col("LSTAR").alias("activity_type")
                if "LSTAR" in crco.columns
                else F.lit(None).cast("string").alias("activity_type"),
            )
        )
        schedgroup_silver = schedgroup_silver.join(crco_clean, on="OBJID", how="left")

    schedgroup_conformed = (schedgroup_silver
        .withColumnRenamed("OBJID", "work_centre_id")
        .filter(F.col("work_centre_id").isNotNull())
    )

    print(f"R5Schedgroups rows: {schedgroup_conformed.count():,}")
    schedgroup_conformed.show(5, truncate=False)
    write_conformed(schedgroup_conformed, "r5schedgroups_details")
```

```python
# ============================================================
# STEP 5 — R5events_Details
# AUFK — folder: master-data
# QMEL + AFIH — folder: pm-asset-events
# ============================================================
aufk = safe_read(master_path, "AUFK")
qmel = safe_read(pm_path,     "QMEL")
afih = safe_read(pm_path,     "AFIH")

if aufk: print("\nAUFK columns:", aufk.columns)
if qmel: print("QMEL columns:", qmel.columns)
if afih: print("AFIH columns:", afih.columns)
```

```python
if aufk:
    aufk_clean = (aufk
        .filter(F.col("MANDT") == MANDT)
        .dropDuplicates(["AUFNR"])
        .select(
            F.col("AUFNR"),      # keep for joins
            F.col("AUART").alias("order_type")
            if "AUART" in aufk.columns
            else F.lit(None).cast("string").alias("order_type"),
            F.col("KTEXT").alias("order_description")
            if "KTEXT" in aufk.columns
            else F.lit(None).cast("string").alias("order_description"),
            F.col("IWERK").alias("maintenance_plant")
            if "IWERK" in aufk.columns
            else F.lit(None).cast("string").alias("maintenance_plant"),
            F.col("KOSTL").alias("cost_centre")
            if "KOSTL" in aufk.columns
            else F.lit(None).cast("string").alias("cost_centre"),
            F.col("EQUNR").alias("equipment_number")
            if "EQUNR" in aufk.columns
            else F.lit(None).cast("string").alias("equipment_number"),
            F.col("ERNAM").alias("created_by")
            if "ERNAM" in aufk.columns
            else F.lit(None).cast("string").alias("created_by"),
            F.to_date(F.col("ERDAT"), "yyyyMMdd").alias("creation_date")
            if "ERDAT" in aufk.columns
            else F.lit(None).cast("date").alias("creation_date"),
            F.to_date(F.col("GSTRP"), "yyyyMMdd").alias("planned_start_date")
            if "GSTRP" in aufk.columns
            else F.lit(None).cast("date").alias("planned_start_date"),
            F.to_date(F.col("GLTRP"), "yyyyMMdd").alias("planned_finish_date")
            if "GLTRP" in aufk.columns
            else F.lit(None).cast("date").alias("planned_finish_date"),
            F.col("IPHAS").alias("order_status")
            if "IPHAS" in aufk.columns
            else F.lit(None).cast("string").alias("order_status"),
            F.col("PRIOK").alias("priority")
            if "PRIOK" in aufk.columns
            else F.lit(None).cast("string").alias("priority"),
        )
    )

    events_silver = aufk_clean

    # Join AFIH — PM order header
    if afih:
        afih_clean = (afih
            .filter(F.col("MANDT") == MANDT)
            .dropDuplicates(["AUFNR"])
            .select(
                F.col("AUFNR"),
                F.col("QMNUM").alias("notification_number")
                if "QMNUM" in afih.columns
                else F.lit(None).cast("string").alias("notification_number"),
                F.col("ILOAN").alias("functional_location")
                if "ILOAN" in afih.columns
                else F.lit(None).cast("string").alias("functional_location"),
                F.col("ANLNR").alias("asset_number")
                if "ANLNR" in afih.columns
                else F.lit(None).cast("string").alias("asset_number"),
                F.col("PMAUFNR").alias("pm_order_number")
                if "PMAUFNR" in afih.columns
                else F.lit(None).cast("string").alias("pm_order_number"),
            )
        )
        events_silver = events_silver.join(afih_clean, on="AUFNR", how="left")

    # Join QMEL — PM notifications
    if qmel:
        qmel_clean = (qmel
            .filter(F.col("MANDT") == MANDT)
            .dropDuplicates(["QMNUM"])
            .select(
                F.col("QMNUM").alias("notification_number"),
                F.col("QMART").alias("notification_type")
                if "QMART" in qmel.columns
                else F.lit(None).cast("string").alias("notification_type"),
                F.col("QMTXT").alias("notification_description")
                if "QMTXT" in qmel.columns
                else F.lit(None).cast("string").alias("notification_description"),
                F.col("PRIOK").alias("notification_priority")
                if "PRIOK" in qmel.columns
                else F.lit(None).cast("string").alias("notification_priority"),
                F.to_date(F.col("STRMN"), "yyyyMMdd").alias("required_start_date")
                if "STRMN" in qmel.columns
                else F.lit(None).cast("date").alias("required_start_date"),
                F.to_date(F.col("LTRMN"), "yyyyMMdd").alias("required_end_date")
                if "LTRMN" in qmel.columns
                else F.lit(None).cast("date").alias("required_end_date"),
            )
        )
        # Join via notification_number from AFIH
        if "notification_number" in events_silver.columns:
            events_silver = events_silver.join(
                qmel_clean,
                on="notification_number",
                how="left"
            )

    events_conformed = (events_silver
        .withColumnRenamed("AUFNR", "work_order_number")
        .filter(F.col("work_order_number").isNotNull())
    )

    print(f"R5events rows: {events_conformed.count():,}")
    events_conformed.show(5, truncate=False)
    write_conformed(events_conformed, "r5events_details")
```

```python
# ============================================================
# STEP 6 — Requisition_Details
# EBAN — folder: transaction-data
# ============================================================
eban = safe_read(tx_path, "EBAN")
if eban: print("\nEBAN columns:", eban.columns)
```

```python
if eban:
    requisition_conformed = (eban
        .filter(F.col("MANDT") == MANDT)
        .dropDuplicates(["BANFN"])
        .select(
            F.col("BANFN"),      # keep for rename
            F.col("BNFPO").alias("requisition_item_number")
            if "BNFPO" in eban.columns
            else F.lit(None).cast("string").alias("requisition_item_number"),
            F.to_date(F.col("BADAT"), "yyyyMMdd").alias("requisition_date")
            if "BADAT" in eban.columns
            else F.lit(None).cast("date").alias("requisition_date"),
            F.col("AFNAM").alias("requested_by")
            if "AFNAM" in eban.columns
            else F.lit(None).cast("string").alias("requested_by"),
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
            F.col("WERKS").alias("plant")
            if "WERKS" in eban.columns
            else F.lit(None).cast("string").alias("plant"),
            F.col("KOSTL").alias("cost_centre")
            if "KOSTL" in eban.columns
            else F.lit(None).cast("string").alias("cost_centre"),
            F.col("FRGKZ").alias("release_status")
            if "FRGKZ" in eban.columns
            else F.lit(None).cast("string").alias("release_status"),
            F.col("PREIS").cast("decimal(18,2)").alias("estimated_price")
            if "PREIS" in eban.columns
            else F.lit(None).cast("decimal(18,2)").alias("estimated_price"),
            F.col("EBELN").alias("purchase_order_reference")
            if "EBELN" in eban.columns
            else F.lit(None).cast("string").alias("purchase_order_reference"),
        )
        .withColumnRenamed("BANFN", "requisition_number")
        .filter(F.col("requisition_number").isNotNull())
    )

    print(f"Requisition_Details rows: {requisition_conformed.count():,}")
    requisition_conformed.show(5, truncate=False)
    write_conformed(requisition_conformed, "requisition_details")
```

```python
# ============================================================
# STEP 7 — Requisitions_Parts_Details
# EBAN + EIPO — folder: transaction-data
# ============================================================
eipo = safe_read(tx_path, "EIPO")
if eipo: print("\nEIPO columns:", eipo.columns)
```

```python
if eban:
    eban_parts = (eban
        .filter(F.col("MANDT") == MANDT)
        .filter(~F.col("PSTYP").isin(["D","9"])
                if "PSTYP" in eban.columns else F.lit(True))
        .dropDuplicates(["BANFN","BNFPO"])
        .select(
            F.col("BANFN"),
            F.col("BNFPO"),
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
            F.col("MATKL").alias("material_group")
            if "MATKL" in eban.columns
            else F.lit(None).cast("string").alias("material_group"),
            F.col("WERKS").alias("plant")
            if "WERKS" in eban.columns
            else F.lit(None).cast("string").alias("plant"),
            F.to_date(F.col("BADAT"), "yyyyMMdd").alias("requisition_date")
            if "BADAT" in eban.columns
            else F.lit(None).cast("date").alias("requisition_date"),
            F.col("FRGKZ").alias("release_status")
            if "FRGKZ" in eban.columns
            else F.lit(None).cast("string").alias("release_status"),
        )
    )

    req_parts_silver = eban_parts

    if eipo:
        eipo_clean = (eipo
            .filter(F.col("MANDT") == MANDT)
            .dropDuplicates(["BANFN","BNFPO"])
            .select(
                F.col("BANFN"),
                F.col("BNFPO"),
                F.col("ABART").alias("scheduling_agreement_type")
                if "ABART" in eipo.columns
                else F.lit(None).cast("string").alias("scheduling_agreement_type"),
                F.col("LICFD").alias("delivery_date")
                if "LICFD" in eipo.columns
                else F.lit(None).cast("string").alias("delivery_date"),
            )
        )
        req_parts_silver = req_parts_silver.join(
            eipo_clean, on=["BANFN","BNFPO"], how="left"
        )

    req_parts_conformed = (req_parts_silver
        .withColumnRenamed("BANFN", "requisition_number")
        .withColumnRenamed("BNFPO", "requisition_item_number")
        .filter(F.col("requisition_number").isNotNull())
    )

    print(f"Requisitions_Parts rows: {req_parts_conformed.count():,}")
    req_parts_conformed.show(5, truncate=False)
    write_conformed(req_parts_conformed, "requisitions_parts_details")
```

```python
# ============================================================
# STEP 8 — Requisitions_Services_Details
# EBAN (service lines only) — folder: transaction-data
# ============================================================
if eban:
    req_services_conformed = (eban
        .filter(F.col("MANDT") == MANDT)
        .filter(
            F.col("PSTYP").isin(["D","9"]) | F.col("KNTTP").isin(["F","D"])
            if "PSTYP" in eban.columns and "KNTTP" in eban.columns
            else F.col("PSTYP").isin(["D","9"])
            if "PSTYP" in eban.columns
            else F.lit(True)
        )
        .dropDuplicates(["BANFN","BNFPO"])
        .select(
            F.col("BANFN"),
            F.col("BNFPO"),
            F.col("TXZ01").alias("service_description")
            if "TXZ01" in eban.columns
            else F.lit(None).cast("string").alias("service_description"),
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
            F.col("PSTYP").alias("item_category")
            if "PSTYP" in eban.columns
            else F.lit(None).cast("string").alias("item_category"),
        )
        .withColumnRenamed("BANFN", "requisition_number")
        .withColumnRenamed("BNFPO", "requisition_item_number")
        .filter(F.col("requisition_number").isNotNull())
    )

    print(f"Requisitions_Services rows: {req_services_conformed.count():,}")
    req_services_conformed.show(5, truncate=False)
    write_conformed(req_services_conformed, "requisitions_services_details")
```

```python
# ============================================================
# STEP 9 — Status_Details
# TJ02T        — folder: eam-ecc-raw-tables (hyphen)
# T7QAPBS02 + T7SAPBS02 — folder: reference-and-config
# T5APBS02 + T5BPBS02 + T5DPBS02 + T5HPBS02 +
# T7AEPBS02 + ACCDBS02 — folder: co-budget
# ============================================================
tj02t     = safe_read(eam_path2, "TJ02T")
t7qapbs02 = safe_read(ref_path,  "T7QAPBS02")
t7sapbs02 = safe_read(ref_path,  "T7SAPBS02")
t5apbs02  = safe_read(co_path,   "T5APBS02")
t5bpbs02  = safe_read(co_path,   "T5BPBS02")
t5dpbs02  = safe_read(co_path,   "T5DPBS02")
t5hpbs02  = safe_read(co_path,   "T5HPBS02")
t7aepbs02 = safe_read(co_path,   "T7AEPBS02")
accdbs02  = safe_read(co_path,   "ACCDBS02")

if tj02t: print("\nTJ02T columns:", tj02t.columns)
```

```python
# Build status from TJ02T as primary source
# Union all BS02 variants as supplementary status codes

status_dfs = []

if tj02t:
    tj02t_clean = (tj02t
        .filter(F.col("MANDT") == MANDT)
        if "MANDT" in tj02t.columns else tj02t
    )
    tj02t_clean = (tj02t_clean
        .filter(F.col("SPRAS") == "E")
        if "SPRAS" in tj02t.columns else tj02t_clean
    )
    tj02t_clean = (tj02t_clean
        .dropDuplicates(["ESTAT","STSMA"])
        .select(
            F.col("ESTAT").alias("status_code")
            if "ESTAT" in tj02t.columns
            else F.lit(None).cast("string").alias("status_code"),
            F.col("STSMA").alias("status_profile")
            if "STSMA" in tj02t.columns
            else F.lit(None).cast("string").alias("status_profile"),
            F.col("TXT04").alias("status_description_short")
            if "TXT04" in tj02t.columns
            else F.lit(None).cast("string").alias("status_description_short"),
            F.col("TXT30").alias("status_description")
            if "TXT30" in tj02t.columns
            else F.lit(None).cast("string").alias("status_description"),
            F.lit("SYSTEM").alias("status_type"),
            F.lit("TJ02T").alias("source_table"),
        )
    )
    status_dfs.append(tj02t_clean)

# Union all BS02 variants
for tbl, df in [
    ("T7QAPBS02", t7qapbs02), ("T7SAPBS02", t7sapbs02),
    ("T5APBS02",  t5apbs02),  ("T5BPBS02",  t5bpbs02),
    ("T5DPBS02",  t5dpbs02),  ("T5HPBS02",  t5hpbs02),
    ("T7AEPBS02", t7aepbs02), ("ACCDBS02",  accdbs02),
]:
    if df:
        print(f"{tbl} columns:", df.columns)
        # Each BS02 variant has slightly different columns — use safe select
        bs_clean = (df
            .filter(F.col("MANDT") == MANDT)
            if "MANDT" in df.columns else df
        )
        stat_col  = next((c for c in ["ESTAT","ISTAT","CODE"] if c in df.columns), None)
        prof_col  = next((c for c in ["STSMA","PROFIL"]       if c in df.columns), None)
        txt_col   = next((c for c in ["TXT30","TXT04","BEZEI"] if c in df.columns), None)

        if stat_col:
            bs_clean = (bs_clean
                .dropDuplicates([stat_col])
                .select(
                    F.col(stat_col).alias("status_code"),
                    F.col(prof_col).alias("status_profile")
                    if prof_col else F.lit(None).cast("string").alias("status_profile"),
                    F.lit(None).cast("string").alias("status_description_short"),
                    F.col(txt_col).alias("status_description")
                    if txt_col else F.lit(None).cast("string").alias("status_description"),
                    F.lit("USER").alias("status_type"),
                    F.lit(tbl).alias("source_table"),
                )
            )
            status_dfs.append(bs_clean)

if status_dfs:
    from functools import reduce
    status_conformed = reduce(lambda a, b: a.unionByName(b), status_dfs)
    status_conformed = status_conformed.filter(F.col("status_code").isNotNull())
    print(f"Status_Details rows: {status_conformed.count():,}")
    status_conformed.show(5, truncate=False)
    write_conformed(status_conformed, "status_details")
else:
    print("⚠️ No status tables available")
```

```python
# ============================================================
# STEP 10 — Store_Details
# T001L + T001W — folder: reference-and-config
# ============================================================
t001l = safe_read(ref_path, "T001L")
t001w = safe_read(ref_path, "T001W")

if t001l: print("\nT001L columns:", t001l.columns)
if t001w: print("T001W columns:", t001w.columns)
```

```python
if t001l:
    t001l_clean = (t001l
        .filter(F.col("MANDT") == MANDT)
        if "MANDT" in t001l.columns else t001l
    )
    t001l_clean = (t001l_clean
        .dropDuplicates(["WERKS","LGORT"])
        .select(
            F.col("WERKS"),      # keep for join
            F.col("LGORT"),      # keep for join
            F.col("LGOBE").alias("storage_location_description")
            if "LGOBE" in t001l.columns
            else F.lit(None).cast("string").alias("storage_location_description"),
        )
    )

    store_silver = t001l_clean

    if t001w:
        t001w_clean = (t001w
            .filter(F.col("MANDT") == MANDT)
            if "MANDT" in t001w.columns else t001w
        )
        t001w_clean = (t001w_clean
            .dropDuplicates(["WERKS"])
            .select(
                F.col("WERKS"),
                F.col("NAME1").alias("plant_name")
                if "NAME1" in t001w.columns
                else F.lit(None).cast("string").alias("plant_name"),
                F.col("STRAS").alias("plant_address")
                if "STRAS" in t001w.columns
                else F.lit(None).cast("string").alias("plant_address"),
                F.col("ORT01").alias("plant_city")
                if "ORT01" in t001w.columns
                else F.lit(None).cast("string").alias("plant_city"),
                F.col("LAND1").alias("plant_country")
                if "LAND1" in t001w.columns
                else F.lit(None).cast("string").alias("plant_country"),
                F.col("BUKRS").alias("company_code")
                if "BUKRS" in t001w.columns
                else F.lit(None).cast("string").alias("company_code"),
            )
        )
        store_silver = store_silver.join(t001w_clean, on="WERKS", how="left")

    store_conformed = (store_silver
        .withColumnRenamed("WERKS", "plant_code")
        .withColumnRenamed("LGORT", "storage_location_code")
        .filter(F.col("storage_location_code").isNotNull())
    )

    print(f"Store_Details rows: {store_conformed.count():,}")
    store_conformed.show(5, truncate=False)
    write_conformed(store_conformed, "store_details")
```

```python
# ============================================================
# STEP 11 — Task_Details
# PLPO + PLPH + MAPL — folder: pm-asset-events
# ============================================================
plpo = safe_read(pm_path, "PLPO")
plph = safe_read(pm_path, "PLPH")
mapl = safe_read(pm_path, "MAPL")

if plpo: print("\nPLPO columns:", plpo.columns)
if plph: print("PLPH columns:", plph.columns)
if mapl: print("MAPL columns:", mapl.columns)
```

```python
if plpo:
    plpo_clean = (plpo
        .filter(F.col("MANDT") == MANDT)
        .dropDuplicates(["PLNNR","PLNKN"])
        .select(
            F.col("PLNNR"),      # task list number — keep for joins
            F.col("PLNKN"),      # operation node — keep for joins
            F.col("VORNR").alias("operation_number")
            if "VORNR" in plpo.columns
            else F.lit(None).cast("string").alias("operation_number"),
            F.col("LTXA1").alias("operation_description")
            if "LTXA1" in plpo.columns
            else F.lit(None).cast("string").alias("operation_description"),
            F.col("ARBID").alias("work_centre_id")
            if "ARBID" in plpo.columns
            else F.lit(None).cast("string").alias("work_centre_id"),
            F.col("WERKS").alias("plant")
            if "WERKS" in plpo.columns
            else F.lit(None).cast("string").alias("plant"),
            F.col("DAUNO").cast("decimal(18,3)").alias("normal_duration_hours")
            if "DAUNO" in plpo.columns
            else F.lit(None).cast("decimal(18,3)").alias("normal_duration_hours"),
            F.col("DAUNE").alias("duration_unit")
            if "DAUNE" in plpo.columns
            else F.lit(None).cast("string").alias("duration_unit"),
            F.col("STSTMA").alias("status")
            if "STSTMA" in plpo.columns
            else F.lit(None).cast("string").alias("status"),
        )
    )

    task_silver = plpo_clean

    # Join PLPH — maintenance plan header
    if plph:
        plph_clean = (plph
            .filter(F.col("MANDT") == MANDT)
            .dropDuplicates(["PLNNR"])
            .select(
                F.col("PLNNR"),
                F.col("PLNTXT").alias("task_list_description")
                if "PLNTXT" in plph.columns
                else F.lit(None).cast("string").alias("task_list_description"),
                F.col("WERKS").alias("plan_plant")
                if "WERKS" in plph.columns
                else F.lit(None).cast("string").alias("plan_plant"),
                F.col("STATU").alias("plan_status")
                if "STATU" in plph.columns
                else F.lit(None).cast("string").alias("plan_status"),
            )
        )
        task_silver = task_silver.join(plph_clean, on="PLNNR", how="left")

    # Join MAPL — plan to object assignment
    if mapl:
        mapl_clean = (mapl
            .filter(F.col("MANDT") == MANDT)
            .dropDuplicates(["PLNNR"])
            .select(
                F.col("PLNNR"),
                F.col("EQUNR").alias("equipment_number")
                if "EQUNR" in mapl.columns
                else F.lit(None).cast("string").alias("equipment_number"),
                F.col("TPLNR").alias("functional_location")
                if "TPLNR" in mapl.columns
                else F.lit(None).cast("string").alias("functional_location"),
                F.col("IWERK").alias("maintenance_plant")
                if "IWERK" in mapl.columns
                else F.lit(None).cast("string").alias("maintenance_plant"),
            )
        )
        task_silver = task_silver.join(mapl_clean, on="PLNNR", how="left")

    task_conformed = (task_silver
        .withColumnRenamed("PLNNR", "task_list_number")
        .withColumnRenamed("PLNKN", "operation_node")
        .filter(F.col("task_list_number").isNotNull())
    )

    print(f"Task_Details rows: {task_conformed.count():,}")
    task_conformed.show(5, truncate=False)
    write_conformed(task_conformed, "task_details")
```

```python
# ============================================================
# STEP 12 — Tax_Details
# T007A — folder: reference-and-config
# T007S + KONP — folder: eam_ecc_raw_tables (underscore)
# ============================================================
t007a = safe_read(ref_path,  "T007A")
t007s = safe_read(eam_path,  "T007S")
konp  = safe_read(eam_path,  "KONP")

if t007a: print("\nT007A columns:", t007a.columns)
if t007s: print("T007S columns:", t007s.columns)
if konp:  print("KONP  columns:", konp.columns)
```

```python
if t007a:
    t007a_clean = (t007a
        .filter(F.col("MANDT") == MANDT)
        if "MANDT" in t007a.columns else t007a
    )
    t007a_clean = (t007a_clean
        .dropDuplicates(["MWSKZ","ALAND"])
        .select(
            F.col("MWSKZ"),      # keep for joins
            F.col("ALAND"),      # keep for joins
            F.col("ZMWSK").alias("tax_type")
            if "ZMWSK" in t007a.columns
            else F.lit(None).cast("string").alias("tax_type"),
            F.col("XINACT").alias("inactive_flag")
            if "XINACT" in t007a.columns
            else F.lit(None).cast("string").alias("inactive_flag"),
        )
    )

    tax_silver = t007a_clean

    # Join T007S — tax descriptions
    if t007s:
        t007s_clean = (t007s
            .filter(F.col("MANDT") == MANDT)
            if "MANDT" in t007s.columns else t007s
        )
        t007s_clean = (t007s_clean
            .filter(F.col("SPRAS") == "E"
                    if "SPRAS" in t007s.columns else F.lit(True))
            .dropDuplicates(["MWSKZ","ALAND"])
            .select(
                F.col("MWSKZ"),
                F.col("ALAND"),
                F.col("TEXT1").alias("tax_description")
                if "TEXT1" in t007s.columns
                else F.lit(None).cast("string").alias("tax_description"),
            )
        )
        tax_silver = tax_silver.join(
            t007s_clean, on=["MWSKZ","ALAND"], how="left"
        )

    # Join KONP — tax rates from condition records
    if konp:
        konp_clean = (konp
            .filter(F.col("MANDT") == MANDT)
            if "MANDT" in konp.columns else konp
        )
        konp_clean = (konp_clean
            .dropDuplicates(["KNUMH"])
            .select(
                F.col("KNUMH").alias("condition_record_number"),
                F.col("KSCHL").alias("condition_type")
                if "KSCHL" in konp.columns
                else F.lit(None).cast("string").alias("condition_type"),
                F.col("KBETR").cast("decimal(18,4)").alias("condition_rate")
                if "KBETR" in konp.columns
                else F.lit(None).cast("decimal(18,4)").alias("condition_rate"),
                F.col("KONWA").alias("condition_currency")
                if "KONWA" in konp.columns
                else F.lit(None).cast("string").alias("condition_currency"),
            )
        )
        # KONP joins via condition number — store separately
        # Cannot direct-join to T007A without KNUMH key
        # Write T007A+T007S as primary, KONP rates as supplementary
        print(f"KONP condition records: {konp_clean.count():,}")

    tax_conformed = (tax_silver
        .withColumnRenamed("MWSKZ", "tax_code")
        .withColumnRenamed("ALAND", "country_code")
        .filter(F.col("tax_code").isNotNull())
    )

    print(f"Tax_Details rows: {tax_conformed.count():,}")
    tax_conformed.show(5, truncate=False)
    write_conformed(tax_conformed, "tax_details")
```

```python
# ============================================================
# STEP 13 — User_Details
# USR02 + USR21 — folder: eam_ecc_raw_tables (underscore)
# AGR_USERS     — folder: hr
# ============================================================
usr02     = safe_read(eam_path, "USR02")
usr21     = safe_read(eam_path, "USR21")
agr_users = safe_read(hr_path,  "AGR_USERS")

if usr02:     print("\nUSR02     columns:", usr02.columns)
if usr21:     print("USR21     columns:", usr21.columns)
if agr_users: print("AGR_USERS columns:", agr_users.columns)
```

```python
if usr02:
    usr02_clean = (usr02
        .filter(F.col("MANDT") == MANDT)
        .dropDuplicates(["BNAME"])
        .select(
            F.col("BNAME"),      # keep for joins
            F.col("USTYP").alias("user_type")
            if "USTYP" in usr02.columns
            else F.lit(None).cast("string").alias("user_type"),
            F.col("CLASS").alias("user_class")
            if "CLASS" in usr02.columns
            else F.lit(None).cast("string").alias("user_class"),
            F.to_date(F.col("GLTGV"), "yyyyMMdd").alias("valid_from")
            if "GLTGV" in usr02.columns
            else F.lit(None).cast("date").alias("valid_from"),
            F.to_date(F.col("GLTGB"), "yyyyMMdd").alias("valid_to")
            if "GLTGB" in usr02.columns
            else F.lit(None).cast("date").alias("valid_to"),
            F.col("TRDAT").alias("last_login_date")
            if "TRDAT" in usr02.columns
            else F.lit(None).cast("string").alias("last_login_date"),
            F.when(F.col("BNAME").isNotNull(), "Active")
             .alias("user_status"),
        )
    )

    user_silver = usr02_clean

    # Join USR21 — person link (connects user to person number)
    if usr21:
        usr21_clean = (usr21
            .filter(F.col("MANDT") == MANDT)
            .dropDuplicates(["BNAME"])
            .select(
                F.col("BNAME"),
                F.col("PERSNUMBER").alias("person_number")
                if "PERSNUMBER" in usr21.columns
                else F.lit(None).cast("string").alias("person_number"),
                F.col("KOSTL").alias("cost_centre")
                if "KOSTL" in usr21.columns
                else F.lit(None).cast("string").alias("cost_centre"),
            )
        )
        user_silver = user_silver.join(usr21_clean, on="BNAME", how="left")

    # Join AGR_USERS — role assignments
    if agr_users:
        agr_clean = (agr_users
            .filter(F.col("MANDT") == MANDT)
            .dropDuplicates(["UNAME","AGR_NAME"])
            .select(
                F.col("UNAME").alias("BNAME"),
                F.col("AGR_NAME").alias("role_name"),
                F.to_date(F.col("FROM_DAT"), "yyyyMMdd").alias("role_from_date")
                if "FROM_DAT" in agr_users.columns
                else F.lit(None).cast("date").alias("role_from_date"),
                F.to_date(F.col("TO_DAT"), "yyyyMMdd").alias("role_to_date")
                if "TO_DAT" in agr_users.columns
                else F.lit(None).cast("date").alias("role_to_date"),
            )
        )
        user_silver = user_silver.join(agr_clean, on="BNAME", how="left")

    user_conformed = (user_silver
        .withColumnRenamed("BNAME", "username")
        .filter(F.col("username").isNotNull())
    )

    print(f"User_Details rows: {user_conformed.count():,}")
    user_conformed.show(5, truncate=False)
    write_conformed(user_conformed, "user_details")
```

```python
# ============================================================
# STEP 14 — Quality Report — all Part 3 tables
# ============================================================
results = {
    "quotation_requests_parts_details"    : ("rfq_number",              "ekap_conformed"),
    "quotation_requests_services_details" : ("rfq_purchase_order_number","ekpv_conformed"),
    "r5objects_details"                   : ("equipment_number",         "r5obj_conformed"),
    "r5schedgroups_details"               : ("work_centre_id",           "schedgroup_conformed"),
    "r5events_details"                    : ("work_order_number",        "events_conformed"),
    "requisition_details"                 : ("requisition_number",       "requisition_conformed"),
    "requisitions_parts_details"          : ("requisition_number",       "req_parts_conformed"),
    "requisitions_services_details"       : ("requisition_number",       "req_services_conformed"),
    "status_details"                      : ("status_code",              "status_conformed"),
    "store_details"                       : ("storage_location_code",    "store_conformed"),
    "task_details"                        : ("task_list_number",         "task_conformed"),
    "tax_details"                         : ("tax_code",                 "tax_conformed"),
    "user_details"                        : ("username",                 "user_conformed"),
}

print(f"\n{'='*65}")
print(f"EAM Part 3 Conformed Layer — Quality Report")
print(f"{'='*65}")
for name, (key, var) in results.items():
    try:
        df       = eval(var)
        total    = df.count()
        null_key = df.filter(F.col(key).isNull()).count()
        print(f"{name:<45} rows: {total:>8,}   null_key: {null_key:>5,}")
    except:
        print(f"{name:<45} ⚠️  not processed")
print(f"{'='*65}")
```