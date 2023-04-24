output "jdbc_connection_string" {
  description = "JDBC Connection string for the Azure SQL Database."
  value       = "jdbc:sqlserver://${azurerm_mssql_server.sql-server.fully_qualified_domain_name}:1433;database=azurerm_mssql_server.sql-db.name"
}