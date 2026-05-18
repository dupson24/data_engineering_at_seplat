```python
# ============================================================
# SRM — Multi-Table Bronze → Silver → Conformed
# Full descriptive column and table names
# ============================================================

raw_base       = "/mnt/sap-ecc-datasphere/sap-ecc-raw"
curated_path   = "/mnt/sap-ecc-datasphere/sap-ecc-curated/srm"
conformed_path = "/mnt/sap-ecc-datasphere/sap-ecc-conformed/srm"

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
    except Exception as e:
        print(f"{table_name} delta  : not available")

    return initial
```

```python
# ============================================================
# STEP 1 — EKKO → srm.purchase_order_headers
# ============================================================
tx_path = f"{raw_base}/transaction-data"

ekko = read_table(tx_path, "EKKO")
print("\nEKKO columns:", ekko.columns)

ekko_conformed = (ekko
    .filter(F.col("MANDT") == MANDT)
    .dropDuplicates(["EBELN"])
    .select(
        F.col("EBELN").alias("purchase_order_number"),
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
    .filter(F.col("purchase_order_number").isNotNull())
)

spark.conf.set("spark.databricks.delta.formatCheck.enabled", "false")
ekko_conformed.write.mode("overwrite").format("parquet").option("compression","snappy").save(f"{conformed_path}/purchase_order_headers")
spark.conf.set("spark.databricks.delta.formatCheck.enabled", "true")
print(f"✅ purchase_order_headers: {ekko_conformed.count():,} rows")
```

```python
# ============================================================
# STEP 2 — EKPO → srm.purchase_order_items
# ============================================================
ekpo = read_table(tx_path, "EKPO")
print("\nEKPO columns:", ekpo.columns)

ekpo_conformed = (ekpo
    .filter(F.col("MANDT") == MANDT)
    .dropDuplicates(["EBELN","EBELP"])
    .select(
        F.col("EBELN").alias("purchase_order_number"),
        F.col("EBELP").alias("purchase_order_item_number"),
        F.col("MATNR").alias("material_code"),
        F.col("TXZ01").alias("item_description"),
        F.col("MENGE").cast("decimal(18,3)").alias("order_quantity"),
        F.col("MEINS").alias("unit_of_measure"),
        F.col("NETPR").cast("decimal(18,2)").alias("net_price"),
        F.col("MATKL").alias("material_group"),
        F.col("WERKS").alias("plant"),
        F.to_date(F.col("EINDT"), "yyyyMMdd").alias("delivery_date"),
        F.when(F.col("LOEKZ") == "L", "Deleted")
         .otherwise("Active").alias("item_status")
        if "LOEKZ" in ekpo.columns
        else F.lit("Active").alias("item_status"),
        F.when(F.col("ELIKZ") == "X", "Complete")
         .otherwise("Open").alias("delivery_status")
        if "ELIKZ" in ekpo.columns
        else F.lit("Open").alias("delivery_status"),
        F.col("PSTYP").alias("item_category")
        if "PSTYP" in ekpo.columns
        else F.lit(None).cast("string").alias("item_category"),
        F.col("LIFNR").alias("supplier_code")
        if "LIFNR" in ekpo.columns
        else F.lit(None).cast("string").alias("supplier_code"),
    )
    .filter(F.col("purchase_order_number").isNotNull())
)

spark.conf.set("spark.databricks.delta.formatCheck.enabled", "false")
ekpo_conformed.write.mode("overwrite").format("parquet").option("compression","snappy").save(f"{conformed_path}/purchase_order_items")
spark.conf.set("spark.databricks.delta.formatCheck.enabled", "true")
print(f"✅ purchase_order_items: {ekpo_conformed.count():,} rows")
```

```python
# ============================================================
# STEP 3 — AUFK → srm.work_order_master
# ============================================================
aufk = read_table(tx_path, "AUFK")
print("\nAUFK columns:", aufk.columns)

aufk_conformed = (aufk
    .filter(F.col("MANDT") == MANDT)
    .dropDuplicates(["AUFNR"])
    .select(
        F.col("AUFNR").alias("work_order_number"),
        F.col("AUART").alias("work_order_type")
        if "AUART" in aufk.columns
        else F.lit(None).cast("string").alias("work_order_type"),
        F.col("KTEXT").alias("work_order_description")
        if "KTEXT" in aufk.columns
        else F.lit(None).cast("string").alias("work_order_description"),
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
        F.col("IPHAS").alias("work_order_status")
        if "IPHAS" in aufk.columns
        else F.lit(None).cast("string").alias("work_order_status"),
        F.col("PRIOK").alias("priority")
        if "PRIOK" in aufk.columns
        else F.lit(None).cast("string").alias("priority"),
        F.col("AUFPL").alias("routing_number")
        if "AUFPL" in aufk.columns
        else F.lit(None).cast("string").alias("routing_number"),
    )
    .filter(F.col("work_order_number").isNotNull())
)

spark.conf.set("spark.databricks.delta.formatCheck.enabled", "false")
aufk_conformed.write.mode("overwrite").format("parquet").option("compression","snappy").save(f"{conformed_path}/work_order_master")
spark.conf.set("spark.databricks.delta.formatCheck.enabled", "true")
print(f"✅ work_order_master: {aufk_conformed.count():,} rows")
```

```python
# ============================================================
# STEP 4 — BNKA → srm.bank_details
# ============================================================
bnka = read_table(raw_base, "BNKA")
print("\nBNKA columns:", bnka.columns)

bnka_conformed = (bnka
    .filter(F.col("MANDT") == MANDT)
    .dropDuplicates(["BANKL"])
    .select(
        F.col("BANKL").alias("bank_sort_code"),
        F.col("BANKA").alias("bank_name"),
        F.col("BANKS").alias("bank_country"),
        F.col("BRNCH").alias("bank_branch")
        if "BRNCH" in bnka.columns
        else F.lit(None).cast("string").alias("bank_branch"),
        F.col("STRAS").alias("bank_street_address")
        if "STRAS" in bnka.columns
        else F.lit(None).cast("string").alias("bank_street_address"),
        F.col("ORT01").alias("bank_city")
        if "ORT01" in bnka.columns
        else F.lit(None).cast("string").alias("bank_city"),
        F.col("SWIFT").alias("swift_code")
        if "SWIFT" in bnka.columns
        else F.lit(None).cast("string").alias("swift_code"),
        F.to_date(F.col("ERDAT"), "yyyyMMdd").alias("created_date")
        if "ERDAT" in bnka.columns
        else F.lit(None).cast("date").alias("created_date"),
    )
    .filter(F.col("bank_sort_code").isNotNull())
)

spark.conf.set("spark.databricks.delta.formatCheck.enabled", "false")
bnka_conformed.write.mode("overwrite").format("parquet").option("compression","snappy").save(f"{conformed_path}/bank_details")
spark.conf.set("spark.databricks.delta.formatCheck.enabled", "true")
print(f"✅ bank_details: {bnka_conformed.count():,} rows")
```

```python
# ============================================================
# STEP 5 — EBAN + EIPO → srm.requisitions
# ============================================================
eban = read_table(tx_path, "EBAN")
print("\nEBAN columns:", eban.columns)

try:
    eipo = read_table(tx_path, "EIPO")
    print("EIPO columns:", eipo.columns)
except Exception as e:
    print(f"EIPO not available: {e}")
    eipo = None

eban_clean = (eban
    .filter(F.col("MANDT") == MANDT)
    .dropDuplicates(["BANFN","BNFPO"])
    .select(
        F.col("BANFN").alias("requisition_number"),
        F.col("BNFPO").alias("requisition_item_number"),
        F.col("MATKL").alias("material_group")
        if "MATKL" in eban.columns
        else F.lit(None).cast("string").alias("material_group"),
        F.col("TXZ01").alias("item_description")
        if "TXZ01" in eban.columns
        else F.lit(None).cast("string").alias("item_description"),
        F.col("PREIS").cast("decimal(18,2)").alias("estimated_price")
        if "PREIS" in eban.columns
        else F.lit(None).cast("decimal(18,2)").alias("estimated_price"),
        F.col("MEINS").alias("unit_of_measure")
        if "MEINS" in eban.columns
        else F.lit(None).cast("string").alias("unit_of_measure"),
        F.col("MENGE").cast("decimal(18,3)").alias("requested_quantity")
        if "MENGE" in eban.columns
        else F.lit(None).cast("decimal(18,3)").alias("requested_quantity"),
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
        F.col("EBELN").alias("purchase_order_reference")
        if "EBELN" in eban.columns
        else F.lit(None).cast("string").alias("purchase_order_reference"),
        F.col("PSTYP").alias("item_category")
        if "PSTYP" in eban.columns
        else F.lit(None).cast("string").alias("item_category"),
    )
)

# Join EIPO if available
if eipo:
    eipo_clean = (eipo
        .filter(F.col("MANDT") == MANDT)
        .dropDuplicates(["BANFN","BNFPO"])
        .select(
            F.col("BANFN").alias("requisition_number"),
            F.col("BNFPO").alias("requisition_item_number"),
            *[F.col(c) for c in ["ABART","LICFD"] if c in eipo.columns]
        )
    )
    requisitions_conformed = eban_clean.join(
        eipo_clean,
        on=["requisition_number","requisition_item_number"],
        how="left"
    )
else:
    requisitions_conformed = eban_clean

requisitions_conformed = requisitions_conformed.filter(
    F.col("requisition_number").isNotNull()
)

spark.conf.set("spark.databricks.delta.formatCheck.enabled", "false")
requisitions_conformed.write.mode("overwrite").format("parquet").option("compression","snappy").save(f"{conformed_path}/requisitions")
spark.conf.set("spark.databricks.delta.formatCheck.enabled", "true")
print(f"✅ requisitions: {requisitions_conformed.count():,} rows")
```

```python
# ============================================================
# STEP 6 — T023 + T024 → srm.supplier_category
# ============================================================
ref_path = f"{raw_base}/reference-and-config"

t023 = read_table(ref_path, "T023")
t024 = read_table(ref_path, "T024")

print("\nT023 columns:", t023.columns)
print("T024 columns:", t024.columns)

t023_clean = (t023
    .filter(F.col("MANDT") == MANDT)
    .dropDuplicates(["MATKL"])
    .select(
        F.col("MATKL").alias("material_group_code"),
        F.col("WGBEZ").alias("material_group_description")
        if "WGBEZ" in t023.columns
        else F.lit(None).cast("string").alias("material_group_description"),
    )
)

t024_clean = (t024
    .filter(F.col("MANDT") == MANDT)
    .dropDuplicates(["EKGRP"])
    .select(
        F.col("EKGRP").alias("purchasing_group_code"),
        F.col("EKNAM").alias("purchasing_group_description")
        if "EKNAM" in t024.columns
        else F.lit(None).cast("string").alias("purchasing_group_description"),
    )
)

supplier_category_conformed = (t023_clean
    .crossJoin(t024_clean)
    .select(
        F.monotonically_increasing_id().cast("int").alias("category_id"),
        F.col("purchasing_group_code"),
        F.col("purchasing_group_description"),
        F.col("material_group_code"),
        F.col("material_group_description"),
        F.current_date().alias("created_date"),
    )
)

spark.conf.set("spark.databricks.delta.formatCheck.enabled", "false")
supplier_category_conformed.write.mode("overwrite").format("parquet").option("compression","snappy").save(f"{conformed_path}/supplier_category")
spark.conf.set("spark.databricks.delta.formatCheck.enabled", "true")
print(f"✅ supplier_category: {supplier_category_conformed.count():,} rows")
```

```python
# ============================================================
# STEP 7 — EKAB → srm.tenders
# ============================================================
try:
    ekab = read_table(raw_base, "EKAB")
    print("\nEKAB columns:", ekab.columns)

    tenders_conformed = (ekab
        .filter(F.col("MANDT") == MANDT)
        .dropDuplicates(["EBELN","EBELP"])
        .select(
            F.col("EBELN").alias("purchase_order_number"),
            F.col("EBELP").alias("tender_item_number"),
            F.col("LIFNR").alias("supplier_code")
            if "LIFNR" in ekab.columns
            else F.lit(None).cast("string").alias("supplier_code"),
            F.col("TXZ01").alias("tender_description")
            if "TXZ01" in ekab.columns
            else F.lit(None).cast("string").alias("tender_description"),
            F.col("WERKS").alias("plant")
            if "WERKS" in ekab.columns
            else F.lit(None).cast("string").alias("plant"),
            F.to_date(F.col("BEDAT"), "yyyyMMdd").alias("tender_posted_date")
            if "BEDAT" in ekab.columns
            else F.lit(None).cast("date").alias("tender_posted_date"),
            F.to_date(F.col("KDATB"), "yyyyMMdd").alias("tender_open_date")
            if "KDATB" in ekab.columns
            else F.lit(None).cast("date").alias("tender_open_date"),
            F.to_date(F.col("KDATE"), "yyyyMMdd").alias("tender_close_date")
            if "KDATE" in ekab.columns
            else F.lit(None).cast("date").alias("tender_close_date"),
        )
        .filter(F.col("purchase_order_number").isNotNull())
    )

    spark.conf.set("spark.databricks.delta.formatCheck.enabled", "false")
    tenders_conformed.write.mode("overwrite").format("parquet").option("compression","snappy").save(f"{conformed_path}/tenders")
    spark.conf.set("spark.databricks.delta.formatCheck.enabled", "true")
    print(f"✅ tenders: {tenders_conformed.count():,} rows")

except Exception as e:
    print(f"EKAB not available: {e}")
```

```python
# ============================================================
# STEP 8 — VBRK → srm.transactions
# ============================================================
vbrk = read_table(tx_path, "VBRK")
print("\nVBRK columns:", vbrk.columns)

transactions_conformed = (vbrk
    .filter(F.col("MANDT") == MANDT)
    .dropDuplicates(["VBELN"])
    .select(
        F.col("VBELN").alias("transaction_id"),
        F.col("VGBEL").alias("origin_document_number")
        if "VGBEL" in vbrk.columns
        else F.lit(None).cast("string").alias("origin_document_number"),
        F.col("SPART").alias("issue_type")
        if "SPART" in vbrk.columns
        else F.lit(None).cast("string").alias("issue_type"),
        F.col("VKBUR").alias("sales_office")
        if "VKBUR" in vbrk.columns
        else F.lit(None).cast("string").alias("sales_office"),
        F.to_date(F.col("FKDAT"), "yyyyMMdd").alias("billing_date")
        if "FKDAT" in vbrk.columns
        else F.lit(None).cast("date").alias("billing_date"),
        F.col("NETWR").cast("decimal(18,2)").alias("total_sales_value")
        if "NETWR" in vbrk.columns
        else F.lit(None).cast("decimal(18,2)").alias("total_sales_value"),
        F.col("SKFBT").cast("decimal(18,2)").alias("discount_amount")
        if "SKFBT" in vbrk.columns
        else F.lit(None).cast("decimal(18,2)").alias("discount_amount"),
        F.col("VKBUR").alias("from_location")
        if "VKBUR" in vbrk.columns
        else F.lit(None).cast("string").alias("from_location"),
        F.col("VSTEL").alias("to_location")
        if "VSTEL" in vbrk.columns
        else F.lit(None).cast("string").alias("to_location"),
        F.col("VKORG").alias("issued_by_organisation")
        if "VKORG" in vbrk.columns
        else F.lit(None).cast("string").alias("issued_by_organisation"),
        F.col("KUNAG").alias("customer_id")
        if "KUNAG" in vbrk.columns
        else F.lit(None).cast("string").alias("customer_id"),
        F.col("ZLSCH").alias("payment_type")
        if "ZLSCH" in vbrk.columns
        else F.lit(None).cast("string").alias("payment_type"),
        F.col("RFBSK").alias("payment_status")
        if "RFBSK" in vbrk.columns
        else F.lit(None).cast("string").alias("payment_status"),
        F.col("XBLNR").alias("invoice_number")
        if "XBLNR" in vbrk.columns
        else F.lit(None).cast("string").alias("invoice_number"),
        F.col("ERNAM").alias("approved_by")
        if "ERNAM" in vbrk.columns
        else F.lit(None).cast("string").alias("approved_by"),
        F.col("ERDAT").alias("confirmed_date")
        if "ERDAT" in vbrk.columns
        else F.lit(None).cast("string").alias("confirmed_date"),
    )
    .filter(F.col("transaction_id").isNotNull())
)

spark.conf.set("spark.databricks.delta.formatCheck.enabled", "false")
transactions_conformed.write.mode("overwrite").format("parquet").option("compression","snappy").save(f"{conformed_path}/transactions")
spark.conf.set("spark.databricks.delta.formatCheck.enabled", "true")
print(f"✅ transactions: {transactions_conformed.count():,} rows")
```

```python
# ============================================================
# STEP 9 — VBRP → srm.transfers
# ============================================================
vbrp = read_table(tx_path, "VBRP")
print("\nVBRP columns:", vbrp.columns)

transfers_conformed = (vbrp
    .filter(F.col("MANDT") == MANDT)
    .dropDuplicates(["VBELN","POSNR"])
    .select(
        F.col("POSNR").alias("transfer_line_item"),
        F.col("VBELN").alias("transaction_id"),
        F.col("VGBEL").alias("origin_document_number")
        if "VGBEL" in vbrp.columns
        else F.lit(None).cast("string").alias("origin_document_number"),
        F.col("MATNR").alias("material_code")
        if "MATNR" in vbrp.columns
        else F.lit(None).cast("string").alias("material_code"),
        F.col("ARKTX").alias("item_description")
        if "ARKTX" in vbrp.columns
        else F.lit(None).cast("string").alias("item_description"),
        F.col("FKIMG").cast("decimal(18,3)").alias("billed_quantity")
        if "FKIMG" in vbrp.columns
        else F.lit(None).cast("decimal(18,3)").alias("billed_quantity"),
        F.col("VRKME").alias("unit_of_measure")
        if "VRKME" in vbrp.columns
        else F.lit(None).cast("string").alias("unit_of_measure"),
        F.col("NETPR").cast("decimal(18,2)").alias("net_price")
        if "NETPR" in vbrp.columns
        else F.lit(None).cast("decimal(18,2)").alias("net_price"),
        F.col("KBETR").cast("decimal(18,2)").alias("special_price")
        if "KBETR" in vbrp.columns
        else F.lit(None).cast("decimal(18,2)").alias("special_price"),
        F.col("RABGR").cast("decimal(18,2)").alias("discount_percentage")
        if "RABGR" in vbrp.columns
        else F.lit(None).cast("decimal(18,2)").alias("discount_percentage"),
        F.col("WERKS").alias("from_plant")
        if "WERKS" in vbrp.columns
        else F.lit(None).cast("string").alias("from_plant"),
        F.col("LGORT").alias("to_storage_location")
        if "LGORT" in vbrp.columns
        else F.lit(None).cast("string").alias("to_storage_location"),
        F.col("PSTYV").alias("item_category")
        if "PSTYV" in vbrp.columns
        else F.lit(None).cast("string").alias("item_category"),
        F.to_date(F.col("ERDAT"), "yyyyMMdd").alias("transfer_date")
        if "ERDAT" in vbrp.columns
        else F.lit(None).cast("date").alias("transfer_date"),
        F.col("ERNAM").alias("issued_by")
        if "ERNAM" in vbrp.columns
        else F.lit(None).cast("string").alias("issued_by"),
        F.col("RFBSK").alias("payment_status")
        if "RFBSK" in vbrp.columns
        else F.lit(None).cast("string").alias("payment_status"),
    )
    .filter(F.col("transaction_id").isNotNull())
)

spark.conf.set("spark.databricks.delta.formatCheck.enabled", "false")
transfers_conformed.write.mode("overwrite").format("parquet").option("compression","snappy").save(f"{conformed_path}/transfers")
spark.conf.set("spark.databricks.delta.formatCheck.enabled", "true")
print(f"✅ transfers: {transfers_conformed.count():,} rows")
```

```python
# ============================================================
# STEP 10 — LFA1 + LFB1 + LFBK → srm.vendors
# ============================================================
lfa1 = read_table(raw_base, "LFA1")
print("\nLFA1 columns:", lfa1.columns)

try:
    lfb1 = read_table(raw_base, "LFB1")
    print("LFB1 columns:", lfb1.columns)
except:
    print("LFB1 not available")
    lfb1 = None

try:
    lfbk = read_table(raw_base, "LFBK")
    print("LFBK columns:", lfbk.columns)
except:
    print("LFBK not available")
    lfbk = None

lfa1_clean = (lfa1
    .filter(F.col("MANDT") == MANDT)
    .dropDuplicates(["LIFNR"])
    .select(
        F.col("LIFNR").alias("vendor_code"),
        F.col("KTOKK").alias("vendor_account_group")
        if "KTOKK" in lfa1.columns
        else F.lit(None).cast("string").alias("vendor_account_group"),
        F.col("NAME1").alias("business_name")
        if "NAME1" in lfa1.columns
        else F.lit(None).cast("string").alias("business_name"),
        F.col("NAME2").alias("company_name")
        if "NAME2" in lfa1.columns
        else F.lit(None).cast("string").alias("company_name"),
        F.col("STCD3").alias("registration_number")
        if "STCD3" in lfa1.columns
        else F.lit(None).cast("string").alias("registration_number"),
        F.col("SMTP_ADDR").alias("email_address")
        if "SMTP_ADDR" in lfa1.columns
        else F.lit(None).cast("string").alias("email_address"),
        F.col("TELF1").alias("phone_number")
        if "TELF1" in lfa1.columns
        else F.lit(None).cast("string").alias("phone_number"),
        F.col("STRAS").alias("registered_address")
        if "STRAS" in lfa1.columns
        else F.lit(None).cast("string").alias("registered_address"),
        F.col("ORT01").alias("city")
        if "ORT01" in lfa1.columns
        else F.lit(None).cast("string").alias("city"),
        F.col("REGIO").alias("state_region")
        if "REGIO" in lfa1.columns
        else F.lit(None).cast("string").alias("state_region"),
        F.col("LAND1").alias("country")
        if "LAND1" in lfa1.columns
        else F.lit(None).cast("string").alias("country"),
        F.when(F.col("SPERR") == "X", "Blocked")
         .otherwise("Active").alias("vendor_status")
        if "SPERR" in lfa1.columns
        else F.lit("Active").alias("vendor_status"),
        F.col("STCD1").alias("tax_identification_number")
        if "STCD1" in lfa1.columns
        else F.lit(None).cast("string").alias("tax_identification_number"),
        F.col("STCEG").alias("vat_registration_number")
        if "STCEG" in lfa1.columns
        else F.lit(None).cast("string").alias("vat_registration_number"),
        F.to_date(F.col("ERDAT"), "yyyyMMdd").alias("registration_date")
        if "ERDAT" in lfa1.columns
        else F.lit(None).cast("date").alias("registration_date"),
    )
)

# Join LFB1
if lfb1:
    lfb1_clean = (lfb1
        .filter(F.col("MANDT") == MANDT)
        .dropDuplicates(["LIFNR"])
        .select(
            F.col("LIFNR").alias("vendor_code"),
            F.col("ZTERM").alias("payment_terms")
            if "ZTERM" in lfb1.columns
            else F.lit(None).cast("string").alias("payment_terms"),
            F.col("WAERS").alias("currency")
            if "WAERS" in lfb1.columns
            else F.lit(None).cast("string").alias("currency"),
            F.col("AKONT").alias("reconciliation_account")
            if "AKONT" in lfb1.columns
            else F.lit(None).cast("string").alias("reconciliation_account"),
        )
    )
    vendors_silver = lfa1_clean.join(lfb1_clean, on="vendor_code", how="left")
else:
    vendors_silver = lfa1_clean

# Join LFBK
if lfbk:
    lfbk_clean = (lfbk
        .filter(F.col("MANDT") == MANDT)
        .dropDuplicates(["LIFNR"])
        .select(
            F.col("LIFNR").alias("vendor_code"),
            F.col("BANKL").alias("bank_sort_code")
            if "BANKL" in lfbk.columns
            else F.lit(None).cast("string").alias("bank_sort_code"),
            F.col("BANKN").alias("bank_account_number")
            if "BANKN" in lfbk.columns
            else F.lit(None).cast("string").alias("bank_account_number"),
            F.col("BKONT").alias("bank_account_type")
            if "BKONT" in lfbk.columns
            else F.lit(None).cast("string").alias("bank_account_type"),
        )
    )
    vendors_silver = vendors_silver.join(lfbk_clean, on="vendor_code", how="left")

vendors_conformed = vendors_silver.filter(F.col("vendor_code").isNotNull())

spark.conf.set("spark.databricks.delta.formatCheck.enabled", "false")
vendors_conformed.write.mode("overwrite").format("parquet").option("compression","snappy").save(f"{conformed_path}/vendors")
spark.conf.set("spark.databricks.delta.formatCheck.enabled", "true")
print(f"✅ vendors: {vendors_conformed.count():,} rows")
```

```python
# ============================================================
# STEP 11 — Quality Report — all tables
# ============================================================
results = {
    "purchase_order_headers" : (ekko_conformed,              "purchase_order_number"),
    "purchase_order_items"   : (ekpo_conformed,              "purchase_order_number"),
    "work_order_master"      : (aufk_conformed,              "work_order_number"),
    "bank_details"           : (bnka_conformed,              "bank_sort_code"),
    "requisitions"           : (requisitions_conformed,      "requisition_number"),
    "supplier_category"      : (supplier_category_conformed, "category_id"),
    "transactions"           : (transactions_conformed,      "transaction_id"),
    "transfers"              : (transfers_conformed,         "transaction_id"),
    "vendors"                : (vendors_conformed,           "vendor_code"),
}

print(f"\n{'='*60}")
print(f"SRM Conformed Layer — Quality Report")
print(f"{'='*60}")
for name, (df, key) in results.items():
    total    = df.count()
    null_key = df.filter(F.col(key).isNull()).count()
    print(f"{name:<30} rows: {total:>8,}   null_key: {null_key:>5,}")
print(f"{'='*60}")
```