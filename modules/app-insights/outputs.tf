output "connection_string" {
  value     = azurerm_application_insights.appi.connection_string
  sensitive = true
}

output "app_id" {
  value = azurerm_application_insights.appi.app_id
}
