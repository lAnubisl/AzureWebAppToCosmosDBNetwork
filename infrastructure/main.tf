resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = var.resource_group_location
}

resource "random_string" "random" {
  length  = 8
  special = false
  upper   = false
  lower   = true
  numeric = false
}