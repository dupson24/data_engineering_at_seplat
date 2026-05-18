df = (spark.read
      .format("com.sap.spark.Table")
      .option("driver", "com.sap.db.jdbc.Driver")
      .option("url", "jdbc:sap://<SAP_HOST>:30015")
      .option("user", "<username>")
      .option("password", "<password>")
      .option("dbtable", "LFA1")
      .option("client", "100")
      .load())

df.write.mode("overwrite").parquet("abfss://raw@seplatedwstorage.dfs.core.windows.net/LFA1/year=2026/month=04/day=01/")