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

provider "azurerm" {
  features {}
}

provider "databricks" {
  azure_workspace_resource_id = module.adb.adb_id
}

module "rg" {
  source     = "./modules/resource-group"
  name_part1 = var.name_part1
  name_part2 = var.name_part2
  location   = var.location
}

module "app-insights" {
  source              = "./modules/app-insights"
  resource_group_name = module.rg.name
  name_part1          = var.name_part1
  name_part2          = var.name_part2
  location            = var.location
}

module "adb" {
  source                         = "./modules/adb"
  resource_group_name            = module.rg.name
  name_part1                     = var.name_part1
  name_part2                     = var.name_part2
  location                       = var.location
  key_vault_id                   = module.keyvault.kv_id
  username_secret_name           = module.db.username_secret_name
  password_secret_name           = module.db.password_secret_name
  metastore_connection_string    = module.db.jdbc_connection_string
  app_insights_connection_string = module.app-insights.connection_string
}

module "keyvault" {
  source              = "./modules/keyvault"
  resource_group_name = module.rg.name
  name_part1          = var.name_part1
  name_part2          = var.name_part2
  location            = var.location
}


module "db" {
  source              = "./modules/db"
  resource_group_name = module.rg.name
  name_part1          = var.name_part1
  name_part2          = var.name_part2
  location            = var.location
  key_vault_id        = module.keyvault.kv_id
}
