
resource "random_id" "username" {
  byte_length = 10

}
resource "random_password" "password" {
  length  = 10
  special = true
}

resource "azurerm_key_vault_secret" "db_un" {
  name         = "db-username"
  value        = random_id.username.hex
  key_vault_id = var.key_vault_id
}
resource "azurerm_key_vault_secret" "db_pw" {
  name         = "db-password"
  value        = random_password.password.result
  key_vault_id = var.key_vault_id
}

resource "azurerm_mssql_server" "sql-server" {
  name                         = format("sqlserver-%s-%s", var.name_part1, var.name_part2)
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = azurerm_key_vault_secret.db_un.value
  administrator_login_password = azurerm_key_vault_secret.db_pw.value
}

resource "azurerm_mssql_firewall_rule" "azure-services" {
  name             = "Allow"
  server_id        = azurerm_mssql_server.sql-server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_mssql_database" "sql-db" {
  name      = "metastoredb"
  server_id = azurerm_mssql_server.sql-server.id
  sku_name  = "Basic"
}
