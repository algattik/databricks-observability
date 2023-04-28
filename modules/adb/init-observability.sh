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
/dbfs/observability/expand-appinsights-config.py -w "${MAX_WORKERS:-8}" /tmp/template.json /tmp/applicationinsights.json

echo "Copying /tmp/applicationinsights-agent.jar"
cp /dbfs/observability/applicationinsights-agent.jar /tmp/
