#!/bin/sh

set -euxo pipefail  # stop on error

envsubst < /dbfs/observability/applicationinsights.json > /tmp/applicationinsights.json
cp /dbfs/observability/applicationinsights-agent.jar /tmp/