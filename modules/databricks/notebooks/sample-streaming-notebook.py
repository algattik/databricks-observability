# Databricks notebook source
# Dummy streaming job that never ends
(spark
    .readStream
    .format("rate")
    .option("rowsPerSecond", 100)
    .load()
    .writeStream
    .foreach(lambda row : None)
    .start())
