#!/usr/bin/env bash

set -euxo pipefail  # stop on error

if [[ ${DB_IS_DRIVER:-TRUE} = "TRUE" ]]; then
  type="driver"
else
  type="executor"
fi

echo "Installing envsubst and jq"
apt-get install -y gettext jq

echo "Generating /tmp/template.json"
envsubst < /dbfs/observability/applicationinsights-$type.json > /tmp/template.json

echo "Generating /tmp/applicationinsights.json"
jq '.jmxMetrics = ([.jmxMetrics[] | (range(0;3)|tostring) as $d | (.objectName|startswith("metrics:name=databricks.0.")) as $f | .objectName=if $f then (.objectName | "metrics:name=databricks." + $d + "." + ltrimstr("metrics:name=databricks.0.")) else .objectName end | .name=if $f then .name + $d else .name end]|unique)' /tmp/template.json > /tmp/applicationinsights.json

echo "Copying /tmp/applicationinsights-agent.jar"
cp /dbfs/observability/applicationinsights-agent.jar /tmp/
