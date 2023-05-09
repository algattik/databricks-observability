# Databricks notebook source
"""Utilities to configure the OpenTelemetry SDK to export telemetry to
Application Insights. Use the following APIs to _raise_ telemetry:

- Traces: `opentelemetry.trace`
- Metrics: `opentelemetry.metrics`
- Logs: `logging`
"""
from typing import Any, Callable, NamedTuple

_initialized = False  # Stores whether Application Insights was already configured.

class ApplicationInsightsConfiguration(NamedTuple):
    import logging

    """Holds configuration for configuring the OpenTelemetry exporters for Azure Monitor.

    Fields:
    :connection_string: connection string of the Application Insights instance
    :service_name: name of the service
    :service_version: version of the service
    :logging_level: logging level, defined in terms of the standard Python logging facility
    :tracing_export_interval_ms: how frequently to export traces
    :logging_export_interval_ms: how frequently to export logs

    The metrics export interval can only be configured through setting the
    OTEL_METRIC_EXPORT_INTERVAL environment variable.
    """

    connection_string: str
    service_name: str
    service_version: str
    logging_level: int = logging.INFO
    tracing_export_interval_ms: int = 15000
    logging_export_interval_ms: int = 15000

    def configure(self):
        from azure.monitor.opentelemetry import configure_azure_monitor
        from opentelemetry.sdk.resources import Resource, ResourceAttributes
        from uuid import uuid4

        assert self.connection_string, "connection_string must be defined"
        # Service name has a default SDK environment variable. For consistency
        # we require the parameter instead of the environment variable.
        # https://opentelemetry.io/docs/concepts/sdk-configuration/general-sdk-configuration/
        assert self.service_name, "service_name must be defined"
        assert self.service_version, "service_version must be defined"

        # Configure Azure Monitor exporters for the OpenTelemetry SDK.
        global _initialized
        if not _initialized:
            configure_azure_monitor(
                connection_string=self.connection_string,
                resource=Resource.create({
                    ResourceAttributes.SERVICE_NAME: self.service_name,
                    ResourceAttributes.SERVICE_INSTANCE_ID: str(uuid4()),
                    ResourceAttributes.SERVICE_VERSION: self.service_version,
                }),
                tracing_export_interval_ms=self.tracing_export_interval_ms,
                logging_export_interval_ms=self.logging_export_interval_ms,
                logging_level=self.logging_level
            )

            _initialized = True


def default_notebook_configuration() -> ApplicationInsightsConfiguration:
    """Gets the default Application Insights configuration based on convention for all Databricks
    notebooks in our solution. Meaning:

    - The `ApplicationInsightsConnectionString` is set in the `APPLICATIONINSIGHTS_CONNECTION_STRING`
      environment variable."""

    import os

    return ApplicationInsightsConfiguration(
        connection_string=os.getenv("APPLICATIONINSIGHTS_CONNECTION_STRING"),
        service_name=dbutils.notebook.entry_point.getDbutils().notebook().getContext().notebookPath().get(),
        service_version="1.0")


def execute_with_telemetry_export(
    func: Callable,
    configuration: ApplicationInsightsConfiguration = default_notebook_configuration()):
    """Executes the action with configured setup for OpenTelemetry instrumentation to export
    to Application Insights. This should be called only once per application (idempotency is not guaranteed).

    Parameters:
    :func: function to execute after the OpenTelemetry SDK was configured correctly
    :configuration: Application Insights configuration

    Refer to the tests to see example usage.
    """

    from opentelemetry import trace, metrics, _logs

    try:
        configuration.configure()
        return func()
    finally:
        # Ensure that the telemetry processors and exporters finished processing
        # telemetry when the function execution finished or errored.
        trace.get_tracer_provider().force_flush()
        metrics.get_meter_provider().force_flush()
        _logs.get_logger_provider().force_flush()


def run(path: str, timeout_seconds: int, arguments: Any = dict()) -> str:
    """This method runs a notebook and returns its exit value."""
    execute_with_telemetry_export(
        lambda: dbutils.notebook.run(path, timeout_seconds, arguments), default_notebook_configuration()
    )

# COMMAND ----------

import logging
from opentelemetry import trace, metrics

default_notebook_configuration().configure()

notebook_name = dbutils.notebook.entry_point.getDbutils().notebook().getContext().notebookPath().get()

tracer = trace.get_tracer(notebook_name)

# Create a new root span, set it as the current span in context
tracer.start_as_current_span(notebook_name)

logger = logging.getLogger(notebook_name)

meter = metrics.get_meter(notebook_name)
