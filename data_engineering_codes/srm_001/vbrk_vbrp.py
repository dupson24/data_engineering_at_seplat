# ============================================================
# STEP 8 — VBRK → srm.transactions
# ============================================================
vbrk = read_table(raw_base, "VBRK")
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


# ============================================================
# STEP 9 — VBRP → srm.transfers
# ============================================================
vbrp = read_table(raw_base, "VBRP")
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