# Databricks notebook source
# MAGIC %md Run a command hitting the SQL Database metastore:

# COMMAND ----------

# MAGIC %sql show tables in samples.nyctaxi

# COMMAND ----------

# MAGIC %md Run a Spark job:

# COMMAND ----------

# MAGIC %sql SELECT * FROM samples.nyctaxi.trips LIMIT 10

# COMMAND ----------

# MAGIC %md Run an operation that causes the job to fail early about 50% of the time:

# COMMAND ----------

from datetime import datetime
invalidOp = 0 / (datetime.now().minute % 2) # causes division by zero at even-numbered minutes

# COMMAND ----------

# MAGIC %md Run an operation that takes about 1 to 5 minutes to complete:

# COMMAND ----------

from pyspark.sql.functions import *
spark.range(1,10000000).repartition(10).agg(median('id'), sum('id')).collect()
