#!/usr/bin/env bash

set -euxo pipefail  # stop on error

if [[ ${DB_IS_DRIVER:-TRUE} = "TRUE" ]]; then
  # Driver JMX metrics are named e.g. `databricks.driver.ExecutorMetrics.DirectPoolMemory`
  DB_NODE_TYPE="driver"
  DB_METRICS_PREFIX="databricks.driver"
else
  # Executor JMX metrics are named e.g. `databricks.0.ExecutorMetrics.DirectPoolMemory`
  # Note that Databricks always runs one executor per worker node.
  DB_NODE_TYPE="worker"
  DB_METRICS_PREFIX="databricks.0"
fi

export DB_NODE_TYPE
export DB_METRICS_PREFIX

echo "Listing /dbfs/observability"
find /dbfs/observability

echo "Installing envsubst"
apt-get install -y gettext

echo "Generating /tmp/applicationinsights.json"
envsubst < /dbfs/observability/applicationinsights.json > /tmp/applicationinsights.json

echo "Copying /tmp/applicationinsights-agent.jar"
cp /dbfs/observability/applicationinsights-agent.jar /tmp/
