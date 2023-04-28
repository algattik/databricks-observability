resource "azurerm_resource_group" "rg" {
  name     = format("rg-%s-%s", var.name_part1, var.name_part2)
  location = var.location
}