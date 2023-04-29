resource "azurerm_databricks_workspace" "adb" {
  name                = format("adbr-%s-%s", var.name_part1, var.name_part2)
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "premium"
}