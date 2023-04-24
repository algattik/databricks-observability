resource "azurerm_resource_group" "rg" {
  name     = format("rg-%s-%s", var.owner_custom, var.purpose_custom)
  location = var.location
}