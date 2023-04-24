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
  source         = "./modules/resource-group"
  owner_custom   = var.owner_custom
  purpose_custom = var.purpose_custom
  location       = var.location
}

module "adb" {
  source                      = "./modules/adb"
  resource_group_name         = module.rg.name
  owner_custom                = var.owner_custom
  purpose_custom              = var.purpose_custom
  location                    = var.location
  key_vault_id                = module.keyvault.kv_id
  key_vault_uri               = module.keyvault.kv_uri
  metastore_connection_string = module.db.jdbc_connection_string
}

module "keyvault" {
  source              = "./modules/keyvault"
  resource_group_name = module.rg.name
  owner_custom        = var.owner_custom
  purpose_custom      = var.purpose_custom
  location            = var.location
}


module "db" {
  source              = "./modules/db"
  resource_group_name = module.rg.name
  owner_custom        = var.owner_custom
  purpose_custom      = var.purpose_custom
  location            = var.location
  key_vault_id        = module.keyvault.kv_id
}
