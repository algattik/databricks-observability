terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.53.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "=1.14.3"
    }
  }
}

data "azurerm_databricks_workspace" "default" {
  resource_group_name = var.resource_group_name
  name                = var.databricks_workspace_name
}

provider "azurerm" {
  features {}
}

provider "databricks" {
  azure_workspace_resource_id = data.azurerm_databricks_workspace.default.id
}

data "azurerm_key_vault" "default" {
  resource_group_name = var.resource_group_name
  name                = var.key_vault_name
}

data "azurerm_application_insights" "default" {
  resource_group_name = var.resource_group_name
  name                = var.app_insights_name
}


module "adb" {
  source                           = "../../modules/adb"
  key_vault_id                     = data.azurerm_key_vault.default.id
  key_vault_uri                    = data.azurerm_key_vault.default.vault_uri
  metastore_jdbc_connection_string = var.metastore_jdbc_connection_string
  metastore_username_secret_name   = var.metastore_username_secret_name
  metastore_password_secret_name   = var.metastore_password_secret_name
  app_insights_connection_string   = data.azurerm_application_insights.default.connection_string
  databricks_cli_profile = var.databricks_cli_profile
}