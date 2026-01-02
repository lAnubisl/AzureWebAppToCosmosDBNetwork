resource "azurerm_cosmosdb_sql_role_assignment" "ra_cosmos_webapp" {
  resource_group_name = azurerm_resource_group.rg.name
  scope               = azurerm_cosmosdb_account.cosmos.id
  account_name        = azurerm_cosmosdb_account.cosmos.name
  role_definition_id  = azurerm_cosmosdb_sql_role_definition.role_definition.id
  principal_id        = azurerm_linux_web_app.webapp.identity[0].principal_id
}

resource "azurerm_cosmosdb_sql_role_assignment" "ra_cosmos_webapp_slot" {
  resource_group_name = azurerm_resource_group.rg.name
  scope               = azurerm_cosmosdb_account.cosmos.id
  account_name        = azurerm_cosmosdb_account.cosmos.name
  role_definition_id  = azurerm_cosmosdb_sql_role_definition.role_definition.id
  principal_id        = azurerm_linux_web_app_slot.webapp_slot.identity[0].principal_id
}

resource "azurerm_role_assignment" "webapp_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_web_app.webapp.identity[0].principal_id
}

resource "azurerm_role_assignment" "webapp_slot_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_web_app_slot.webapp_slot.identity[0].principal_id
}