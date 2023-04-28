# Databricks observability demo

Download the latest [Application Insights Java agent JAR](https://github.com/microsoft/ApplicationInsights-Java/releases) to the project directory.

Rename the file to `applicationinsights-agent.jar`.

```shell
terraform init
terraform apply
```


## Outcomes

Sample metrics, e.g. for `ExecutorMetrics.TotalGCTime`:

![Metrics screenshot](assets/metrics.png)

As well as logs:

![Logs screenshot](assets/logs.png)

## More information

The configuration for the `applicationinsights.json` files was initially generated with this [notebook](assets/dump-jmx.ipynb).
