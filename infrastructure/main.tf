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

# resource "azurerm_role_assignment" "webapp_acr_pull" {
#   scope                = azurerm_container_registry.acr.id
#   role_definition_name = "AcrPull"
#   principal_id         = azurerm_linux_web_app.webapp.identity[0].principal_id
# }

# resource "azurerm_role_assignment" "webapp_slot_acr_pull" {
#   scope                = azurerm_container_registry.acr.id
#   role_definition_name = "AcrPull"
#   principal_id         = azurerm_linux_web_app_slot.webapp_slot.identity[0].principal_id
# }