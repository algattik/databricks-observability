# Databricks observability demo

## Scope

This demo showcases:

- Configuring the [Azure Monitor OpenTelemetry Agent](https://learn.microsoft.com/azure/azure-monitor/app/opentelemetry-enable?tabs=net) for Databricks worker and executor Java processes
- Collecting detailed Spark metrics through JMX
- Collecting request traces to external services
- Collecting Spark logs

Future scope:

- Collecting streaming metrics
- Collecting custom metrics
- Collecting custom Python logs and spans
- Automatically deployed Azure Monitor Workbook or Dashboard

The demo is automated and can be deployed using Terraform with a single command.

## How-to

Download the latest [Application Insights Java agent JAR](https://github.com/microsoft/ApplicationInsights-Java/releases) to the project directory.

Rename the file to `applicationinsights-agent.jar`.

Run:

```shell
terraform init
terraform apply
```

⚠️ This sets up a cluster of two nodes, and a recurring job every minute, so that the cluster never automatically shuts down. This will incur high costs if you forget to tear down the resources!

## Setup

### Overview

The solution deploys Azure Databricks connected to Azure Application Insights for monitoring via the [Spark JMX Sink](https://spark.apache.org/docs/latest/monitoring.html). A Databricks job runs periodically and is set up to fail about 50% of the time, to provide "interesting" logs.

### Init script

The solution contains a cluster node initialization script that generates a configuration file for the agent, based on [templates](modules/adb) in the solution.

Spark JMX Means on executor nodes are [prefixed with a configurable namespace named followed by the executor ID](https://github.com/apache/spark/blob/04816474bfcc05c7d90f7b7e8d35184d95c78cbd/core/src/main/scala/org/apache/spark/metrics/MetricsSystem.scala#L131), which is a different number on on every worker node. The Azure Monitor agent does not allow regular expressions when collecting JMX beans, and init scripts cannot know which executor ID will be assigned to the node they run on. Therefore, as a workaround, the agent configuration collects data for each MBean numbered up to the maximum number of nodes in the cluster. This value must be passed as the `MAX_WORKERS` cluster environment variable.

## Outcomes

In the [Azure Portal](https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/microsoft.insights%2Fcomponents), open the deployed Application Insights resource. Open the `Logs` tab.

Run the sample queries provided to visualize different metrics and logs.

### Tasks

```kql
customMetrics
| where name endswith 'Tasks'
| render timechart
```

![tasks](tasks.png)

### Memory

```kql
customMetrics
| where name startswith "spark"
| where name contains 'Memory'
| project-rename memory_bytes = value
| render timechart
```

![](assets/memory.png)

### Message processing time

```kql
customMetrics
| where name contains "messageProcessingTime"
| project-rename messageProcessingTime_ms = value
| where not(name contains "count")
| render timechart
```

![](assets/messageProcessingTime.png)

### Logs

```kql
traces
```

![](assets/traces.png)

## More information

The configuration for the `applicationinsights.json` files was initially generated with this [notebook](assets/dump-jmx.ipynb).

