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
    "spark.databricks.io.cache.enabled" : true,
    "spark.hadoop.javax.jdo.option.ConnectionDriverName" : "com.microsoft.sqlserver.jdbc.SQLServerDriver",
    "spark.hadoop.javax.jdo.option.ConnectionURL" : var.metastore_connection_string
    "spark.hadoop.javax.jdo.option.ConnectionURLFIXME" : "jdbc:sqlserver://sqlserver-algattik-dbobs.database.windows.net:1433;database=metastoredb"
    "spark.databricks.delta.preview.enabled" : true,
    "spark.hadoop.javax.jdo.option.ConnectionUserName" : data.azurerm_key_vault_secret.db-un.value,
    "datanucleus.fixedDatastore" : false,
    "spark.hadoop.javax.jdo.option.ConnectionPassword" : data.azurerm_key_vault_secret.db-pw.value,
    "spark.driver.maxResultSize" : "32gb",
    "datanucleus.autoCreateSchema" : true,
    "spark.sql.hive.metastore.jars" : "builtin",
    "hive.metastore.schema.verification" : false,
    "datanucleus.schema.autoCreateTables" : true,
    "spark.sql.hive.metastore.version" : "2.3.9"


  }
}

# resource "databricks_secret_scope" "kv" {
#   name = "keyvault-managed"

#   keyvault_metadata {
#     resource_id = var.key_vault_id
#     dns_name    = var.key_vault_uri
#   }
# }