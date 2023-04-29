terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "=1.14.3"
    }
  }
}

data "databricks_node_type" "smallest" {
  local_disk = true
}

data "databricks_spark_version" "latest_lts" {
  long_term_support = true
  depends_on        = [azurerm_databricks_workspace.adb]
}

data "azurerm_key_vault_secret" "db-un" {
  name         = var.username_secret_name
  key_vault_id = var.key_vault_id
}


data "azurerm_key_vault_secret" "db-pw" {
  name         = var.password_secret_name
  key_vault_id = var.key_vault_id
}

resource "azurerm_databricks_workspace" "adb" {
  name                = format("adb-%s-%s", var.name_part1, var.name_part2)
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "premium"
}

resource "databricks_dbfs_file" "log4j2-properties" {
  source = "${path.module}/log4j2.properties"
  path   = "/observability/log4j2.properties"
}

resource "databricks_dbfs_file" "agent" {
  source = "applicationinsights-agent.jar"
  path   = "/observability/applicationinsights-agent.jar"
}

resource "databricks_dbfs_file" "init-observability" {
  source = "${path.module}/init-observability.sh"
  path   = "/observability/init-observability.sh"
}

resource "databricks_dbfs_file" "expand-appinsights-config" {
  source = "${path.module}/expand-appinsights-config.py"
  path   = "/observability/expand-appinsights-config.py"
}

resource "databricks_dbfs_file" "applicationinsights-driver-json" {
  source = "${path.module}/applicationinsights-driver.json"
  path   = "/observability/applicationinsights-driver.json"
}

resource "databricks_dbfs_file" "applicationinsights-executor-json" {
  source = "${path.module}/applicationinsights-executor.json"
  path   = "/observability/applicationinsights-executor.json"
}


locals {
  dbfs_prefix  = "/dbfs"
  java_options = "-javaagent:/tmp/applicationinsights-agent.jar -Dlog4j2.configurationFile=${local.dbfs_prefix}${databricks_dbfs_file.log4j2-properties.path}"
  # Not used, but defined in order to ensure the file is valid JSON.
  user_data1 = jsondecode(file("${path.module}/applicationinsights-driver.json"))
  user_data2 = jsondecode(file("${path.module}/applicationinsights-executor.json"))
}


resource "databricks_cluster" "shared_autoscaling" {
  cluster_name            = format("%s-%s-cluster", var.name_part1, var.name_part2)
  spark_version           = data.databricks_spark_version.latest_lts.id
  node_type_id            = data.databricks_node_type.smallest.id
  autotermination_minutes = 20
  autoscale {
    min_workers = 2
    max_workers = 3
  }
  spark_conf = {
    # Metastore config
    "spark.hadoop.javax.jdo.option.ConnectionDriverName" : "com.microsoft.sqlserver.jdbc.SQLServerDriver",
    "spark.hadoop.javax.jdo.option.ConnectionURL" : var.metastore_connection_string
    "spark.hadoop.javax.jdo.option.ConnectionUserName" : data.azurerm_key_vault_secret.db-un.value,
    "spark.hadoop.javax.jdo.option.ConnectionPassword" : data.azurerm_key_vault_secret.db-pw.value,
    "datanucleus.fixedDatastore" : false,
    "datanucleus.autoCreateSchema" : true,
    "hive.metastore.schema.verification" : false,
    "datanucleus.schema.autoCreateTables" : true,

    # Observability
    "spark.executor.extraJavaOptions" : "${local.java_options}",
    "spark.driver.extraJavaOptions" : "${local.java_options}",
    "spark.metrics.conf.*.sink.jmx.class" : "org.apache.spark.metrics.sink.JmxSink",
    "spark.metrics.namespace" : "spark",
    "spark.metrics.appStatusSource.enabled" : "true",
    # TODO enable streaming metrics - currently not working
    # "spark.sql.streaming.metricsEnabled" : "true",
  }

  spark_env_vars = {
    APPLICATIONINSIGHTS_CONNECTION_STRING = var.app_insights_connection_string
  }

  init_scripts {
    dbfs {
      destination = databricks_dbfs_file.init-observability.dbfs_path
    }
  }

  depends_on = [
    databricks_dbfs_file.log4j2-properties,
    databricks_dbfs_file.agent,
    databricks_dbfs_file.init-observability,
    databricks_dbfs_file.expand-appinsights-config,
    databricks_dbfs_file.applicationinsights-driver-json,
    databricks_dbfs_file.applicationinsights-executor-json
  ]

  cluster_log_conf {
    dbfs {
      destination = "dbfs:/cluster-logs"
    }
  }
}

resource "databricks_notebook" "sample-notebook" {
  source = "${path.module}/sample-notebook.py"
  path   = "/Shared/sample-notebook"
}

resource "databricks_job" "sample-job" {
  name = "Sample unreliable job"

  task {
    task_key = "a"

    existing_cluster_id = databricks_cluster.shared_autoscaling.id

    notebook_task {
      notebook_path = databricks_notebook.sample-notebook.path
    }
  }

  schedule {
    quartz_cron_expression = "0 * * * * ?" # every minute
    timezone_id            = "UTC"
  }
}