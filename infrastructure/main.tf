resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.resource_group_location
}

# resource "azurerm_container_registry_scope_map" "acr_reader" {
#   name                    = "reader"
#   container_registry_name = azurerm_container_registry.acr.name
#   resource_group_name     = azurerm_resource_group.rg.name
#   actions = [
#     "repositories/fastapi-cosmos-app/content/read"
#   ]
# }

# resource "azurerm_container_registry_token" "acr_reader_token" {22
#   name                    = "reader"
#   container_registry_name = azurerm_container_registry.acr.name
#   resource_group_name     = azurerm_resource_group.rg.name
#   scope_map_id            = azurerm_container_registry_scope_map.acr_reader.id
# }


# resource "azurerm_container_registry_token_password" "acr_reader_token_password" {
#   container_registry_token_id = azurerm_container_registry_token.acr_reader_token.id
#   password1 {
#   }
# }

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