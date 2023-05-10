# Databricks notebook source
# exports notebook_name, tracer, logger, meter

# COMMAND ----------

# MAGIC %run ./telemetry-helper

# COMMAND ----------

trips_metric = meter.create_histogram(
    name="trips", description="Number of trips"
)

with tracer.start_as_current_span("process trips"):

    with tracer.start_as_current_span("write trips table"):

        logger.info("Saving data to table %s", "trips2")

        (spark.table("samples.nyctaxi.trips")
        .write
        .mode("overwrite")
        .option("path", spark.conf.get("storage_uri") + "/trips2")
        .saveAsTable("trips2"))

    with tracer.start_as_current_span("count trips table"):

        trips_saved = spark.table("trips2").count()

        trips_metric.record(trips_saved)

        logger.info("%d trips completed", trips_saved)
