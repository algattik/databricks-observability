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

resource "databricks_dbfs_file" "applicationinsights-json" {
  content_base64 = base64encode(local.applicationinsights_json)
  path           = "/observability/applicationinsights.json"
}

locals {
  applicationinsights_json = templatefile("${path.module}/applicationinsights.json", { connectionString = var.app_insights_connection_string })
  dbfs_prefix              = "/dbfs"
  java_options             = "-javaagent:${local.dbfs_prefix}${databricks_dbfs_file.agent.path} -Dlog4j2.configurationFile=${local.dbfs_prefix}${databricks_dbfs_file.log4j2-properties.path}"
}


resource "databricks_cluster" "shared_autoscaling" {
  cluster_name            = format("%s-%s-cluster", var.name_part1, var.name_part2)
  spark_version           = data.databricks_spark_version.latest_lts.id
  node_type_id            = data.databricks_node_type.smallest.id
  autotermination_minutes = 20
  autoscale {
    min_workers = 1
    max_workers = 2
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
    "spark.metrics.namespace" : "databricks",
  }

  cluster_log_conf {
    dbfs {
      destination = "dbfs:/cluster-logs"
    }
  }
}