resource "azurerm_service_plan" "asp" {
  name                = var.service_plan_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = var.service_plan_sku
}

resource "azurerm_linux_web_app" "webapp" {
  name                                           = var.webapp_name
  location                                       = azurerm_resource_group.rg.location
  resource_group_name                            = azurerm_resource_group.rg.name
  service_plan_id                                = azurerm_service_plan.asp.id
  https_only                                     = true
  webdeploy_publish_basic_authentication_enabled = false

  site_config {
    minimum_tls_version = "1.3"
    container_registry_use_managed_identity = true
    application_stack {
      docker_image_name = "nginx"
      # docker_registry_url = "https://${azurerm_container_registry.acr.login_server}"
      # docker_registry_username = azurerm_container_registry_scope_map.acr_reader.name
      # docker_registry_password = azurerm_container_registry_token_password.acr_reader_token_password.password1[0].value
    }
  }

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [
      virtual_network_subnet_id,
      site_config[0].application_stack[0].docker_image_name
    ]
  }
}

resource "azurerm_linux_web_app_slot" "webapp_slot" {
  name           = "stage"
  app_service_id = azurerm_linux_web_app.webapp.id

  site_config {
    always_on = false
    container_registry_use_managed_identity = true
    auto_swap_slot_name = "production"
  }

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [
      virtual_network_subnet_id
    ]
  }
}

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

resource "azurerm_app_service_virtual_network_swift_connection" "vnet_webapp" {
  app_service_id = azurerm_linux_web_app.webapp.id
  subnet_id      = azurerm_subnet.webapp_subnet.id
}

resource "azurerm_app_service_slot_virtual_network_swift_connection" "vnet_webapp_slot" {
  slot_name      = azurerm_linux_web_app_slot.webapp_slot.name
  app_service_id = azurerm_linux_web_app.webapp.id
  subnet_id      = azurerm_subnet.webapp_subnet.id
}
