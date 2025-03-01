resource "azurerm_container_registry" "acr" {
  name                = "dockersafsafjkewrqwr2314"           # Replace with your unique ACR name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}