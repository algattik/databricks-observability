# Databricks notebook source
# azure-monitor-opentelemetry~=1.0.0b10 

# COMMAND ----------

# MAGIC %run ./telemetry-helper

# COMMAND ----------

def main():
    trips_saved = spark.table("trips").count()

    trips_metric0 = meter.create_histogram(
        name="DATAZZZ2trips000", description="Number of trips"
    )

    trips_metric0.record(trips_saved)
    logger.critical("DATAZZZ2 %d trips completed", trips_saved)

execute_with_telemetry_export(main)

# COMMAND ----------

run("sample-notebook (1)", timeout_seconds=0)
