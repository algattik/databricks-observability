# Application Insights

resource "azurerm_application_insights" "appi" {
  name                = format("appi-%s-%s", var.name_part1, var.name_part2)
  resource_group_name = var.resource_group_name
  location            = var.location
  application_type    = "other"
}
