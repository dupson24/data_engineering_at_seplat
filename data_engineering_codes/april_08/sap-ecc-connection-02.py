df = (spark.read
      .format("jdbc")
      .option("url", "jdbc:sap://<SAP_HOST>:30015")
      .option("dbtable", "BSEG")
      .option("user", "<username>")
      .option("password", "<password>")
      .option("fetchsize", "10000")
      .option("pushDownPredicate", "true")
      .load()
      .filter("MANDT = '100'"))

df.write.mode("append").parquet("abfss://raw@seplatedwstorage.dfs.core.windows.net/BSEG/year=2026/month=04/day=01/")