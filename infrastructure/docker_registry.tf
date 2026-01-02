resource "azurerm_container_registry" "acr" {
  name                = local.docker_registry_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = false
}

resource "azurerm_container_registry_scope_map" "acr_writer" {
  name                    = "writer"
  container_registry_name = azurerm_container_registry.acr.name
  resource_group_name     = azurerm_resource_group.rg.name
  actions = [
    "repositories/fastapi-cosmos-app/content/read",
    "repositories/fastapi-cosmos-app/content/write"
  ]
}

resource "azurerm_container_registry_token_password" "acr_writer_token_password" {
  container_registry_token_id = azurerm_container_registry_token.acr_writer_token.id
  password1 {
  }
}

resource "azurerm_container_registry_token" "acr_writer_token" {
  name                    = "writer"
  container_registry_name = azurerm_container_registry.acr.name
  resource_group_name     = azurerm_resource_group.rg.name
  scope_map_id            = azurerm_container_registry_scope_map.acr_writer.id
}