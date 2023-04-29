variable "key_vault_id" {
}

variable "key_vault_uri" {
}

variable "metastore_jdbc_connection_string" {
}

variable "metastore_username_secret_name" {
}

variable "metastore_password_secret_name" {
}

variable "app_insights_connection_string" {
  sensitive = true
}

variable "databricks_cli_profile" {
}
