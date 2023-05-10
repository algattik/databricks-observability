# Databricks notebook source
# MAGIC %run ./telemetry-functions

# COMMAND ----------

import logging
from opentelemetry import trace, metrics

default_notebook_configuration().configure()

notebook_name = dbutils.notebook.entry_point.getDbutils().notebook().getContext().notebookPath().get()

tracer = trace.get_tracer(notebook_name)

# Create a new root span, set it as the current span in context
tracer.start_as_current_span(notebook_name)

logger = logging.getLogger(notebook_name)
logger.setLevel(logging.DEBUG)

meter = metrics.get_meter(notebook_name)
