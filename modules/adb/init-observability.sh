#!/usr/bin/env bash

set -euxo pipefail  # stop on error

if [[ ${DB_IS_DRIVER:-TRUE} = "TRUE" ]]; then
  # Driver JMX metrics are named e.g. `databricks.driver.ExecutorMetrics.DirectPoolMemory`
  METRICS_NAME_PREFIX="Driver "
  METRICS_JMX_NAME_PREFIX="databricks.driver"
else
  # Executor JMX metrics are named e.g. `databricks.0.ExecutorMetrics.DirectPoolMemory`
  # Note that Databricks always runs one executor per worker node.
  METRICS_NAME_PREFIX="Worker "
  METRICS_JMX_NAME_PREFIX="databricks.0"
fi

export METRICS_NAME_PREFIX
export METRICS_JMX_NAME_PREFIX

echo "Listing /dbfs/observability"
find /dbfs/observability

echo "Installing envsubst"
apt-get install -y gettext

echo "Generating /tmp/applicationinsights.json"
envsubst < /dbfs/observability/applicationinsights.json > /tmp/applicationinsights.json

echo "Copying /tmp/applicationinsights-agent.jar"
cp /dbfs/observability/applicationinsights-agent.jar /tmp/
