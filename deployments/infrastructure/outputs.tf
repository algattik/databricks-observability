
output "resource_group_name" {
  value = module.rg.name
}

output "key_vault_name" {
  value = module.keyvault.name
}

output "metastore_jdbc_connection_string" {
  value = module.db.jdbc_connection_string
}

output "metastore_username_secret_name" {
  value = module.db.username_secret_name
}

output "metastore_password_secret_name" {
  value = module.db.password_secret_name
}

output "app_insights_name" {
  value = module.app-insights.name
}

output "databricks_workspace_name" {
  value = module.adb.name
}

output "databricks_workspace_host" {
  value = module.adb.workspace_host
}

