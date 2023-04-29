terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.53.0"
    }
  }
}

provider "azurerm" {
  features {}
}

module "rg" {
  source     = "../../modules/resource-group"
  name_part1 = var.name_part1
  name_part2 = var.name_part2
  location   = var.location
}

module "app-insights" {
  source              = "../../modules/app-insights"
  resource_group_name = module.rg.name
  name_part1          = var.name_part1
  name_part2          = var.name_part2
  location            = var.location
}

module "adb" {
  source              = "../../modules/databricks-workspace"
  resource_group_name = module.rg.name
  name_part1          = var.name_part1
  name_part2          = var.name_part2
  location            = var.location
}

module "keyvault" {
  source              = "../../modules/keyvault"
  resource_group_name = module.rg.name
  name_part1          = var.name_part1
  name_part2          = var.name_part2
  location            = var.location
}


module "db" {
  source              = "../../modules/db"
  resource_group_name = module.rg.name
  name_part1          = var.name_part1
  name_part2          = var.name_part2
  location            = var.location
  key_vault_id        = module.keyvault.kv_id
}
