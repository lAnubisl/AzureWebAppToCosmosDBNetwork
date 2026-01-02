resource "azurerm_service_plan" "asp" {
  name                = local.service_plan_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "P0v3"
}

resource "azurerm_linux_web_app" "webapp" {
  name                                           = local.webapp_name
  location                                       = azurerm_resource_group.rg.location
  resource_group_name                            = azurerm_resource_group.rg.name
  service_plan_id                                = azurerm_service_plan.asp.id
  https_only                                     = true
  webdeploy_publish_basic_authentication_enabled = false

  app_settings = {
    "COSMOS_URL"= azurerm_cosmosdb_account.cosmos.endpoint
    "DATABASE_NAME" = azurerm_cosmosdb_sql_database.db.name
    "CONTAINER_NAME" = azurerm_cosmosdb_sql_container.dbcontainer.name
  }

  site_config {
    minimum_tls_version                     = "1.3"
    container_registry_use_managed_identity = true
    application_stack {
      docker_image_name = "nginx"
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

  app_settings = {
    "COSMOS_URL"= azurerm_cosmosdb_account.cosmos.endpoint
    "DATABASE_NAME" = azurerm_cosmosdb_sql_database.db.name
    "CONTAINER_NAME" = azurerm_cosmosdb_sql_container.dbcontainer.name
  }

  site_config {
    always_on                               = false
    container_registry_use_managed_identity = true
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

resource "azurerm_app_service_virtual_network_swift_connection" "vnet_webapp" {
  app_service_id = azurerm_linux_web_app.webapp.id
  subnet_id      = azurerm_subnet.webapp_subnet.id
}

resource "azurerm_app_service_slot_virtual_network_swift_connection" "vnet_webapp_slot" {
  slot_name      = azurerm_linux_web_app_slot.webapp_slot.name
  app_service_id = azurerm_linux_web_app.webapp.id
  subnet_id      = azurerm_subnet.webapp_subnet.id
}
