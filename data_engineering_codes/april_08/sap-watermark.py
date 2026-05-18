# Datasphere exposes tables via OData or HANA JDBC
df = (spark.read
      .format("jdbc")
      .option("url", "jdbc:sap://<DATASPHERE_HOST>:443")
      .option("dbtable", "LFA1")
      .option("encrypt", "true")
      .option("user", "<datasphere_user>")
      .option("password", "<password>")
      .load())