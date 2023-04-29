output "name" {
  value = azurerm_databricks_workspace.adb.name
}

output "workspace_host" {
  value = "https://${azurerm_databricks_workspace.adb.workspace_url}"
}