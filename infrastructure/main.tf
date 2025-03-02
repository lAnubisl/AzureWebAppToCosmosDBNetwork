resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.resource_group_location
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.virtual_network_name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "webapp_subnet" {
  name                 = "webapp-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  delegation {
    name = "webapp_delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_app_service_virtual_network_swift_connection" "vnet_integration" {
  app_service_id = azurerm_linux_web_app.webapp.id
  subnet_id      = azurerm_subnet.webapp_subnet.id
}

resource "azurerm_subnet" "cosmos_subnet" {
  name                                          = "cosmos-subnet"
  resource_group_name                           = azurerm_resource_group.rg.name
  virtual_network_name                          = azurerm_virtual_network.vnet.name
  address_prefixes                              = ["10.0.2.0/24"]
  private_link_service_network_policies_enabled = false
}

resource "azurerm_service_plan" "asp" {
  name                = var.service_plan_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = var.service_plan_sku
}

resource "azurerm_container_registry" "acr" {
  name                = var.docker_registry_name
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

resource "azurerm_container_registry_scope_map" "acr_reader" {
  name                    = "reader"
  container_registry_name = azurerm_container_registry.acr.name
  resource_group_name     = azurerm_resource_group.rg.name
  actions = [
    "repositories/fastapi-cosmos-app/content/read"
  ]
}

resource "azurerm_container_registry_token" "acr_writer_token" {
  name                    = "writer"
  container_registry_name = azurerm_container_registry.acr.name
  resource_group_name     = azurerm_resource_group.rg.name
  scope_map_id            = azurerm_container_registry_scope_map.acr_writer.id
}

resource "azurerm_container_registry_token" "acr_reader_token" {
  name                    = "reader"
  container_registry_name = azurerm_container_registry.acr.name
  resource_group_name     = azurerm_resource_group.rg.name
  scope_map_id            = azurerm_container_registry_scope_map.acr_reader.id
}

resource "azurerm_container_registry_token_password" "acr_writer_token_password" {
  container_registry_token_id = azurerm_container_registry_token.acr_writer_token.id
  password1 {
  }
}

resource "azurerm_container_registry_token_password" "acr_reader_token_password" {
  container_registry_token_id = azurerm_container_registry_token.acr_reader_token.id
  password1 {
  }
}

# resource "azurerm_role_assignment" "webapp_acr_pull" {
#   scope                = azurerm_container_registry.acr.id
#   role_definition_name = "AcrPull"
#   principal_id         = azurerm_linux_web_app.webapp.identity[0].principal_id
# }

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
      docker_registry_url = "https://${azurerm_container_registry.acr.login_server}"
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
    container_registry_use_managed_identity = true
    auto_swap_slot_name = "production"
  }
}

resource "azurerm_cosmosdb_account" "cosmos" {
  name                = var.cosmosdb_account_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  public_network_access_enabled         = false
  is_virtual_network_filter_enabled     = false
  network_acl_bypass_for_azure_services = true
  local_authentication_disabled         = false
  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.rg.location
    failover_priority = 0
  }

  capabilities {
    name = "EnableServerless"
  }
}

resource "azurerm_cosmosdb_sql_database" "db" {
  name                = var.cosmosdb_database_name
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.cosmos.name
}

resource "azurerm_cosmosdb_sql_container" "dbcontainer" {
  name                  = "users"
  resource_group_name   = azurerm_resource_group.rg.name
  account_name          = azurerm_cosmosdb_account.cosmos.name
  database_name         = azurerm_cosmosdb_sql_database.db.name
  partition_key_paths   = ["/id"]
  partition_key_version = 1
  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/*"
    }
  }
}

resource "azurerm_private_endpoint" "cosmos_pe" {
  name                = var.cosmosdb_private_endpoint_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.cosmos_subnet.id

  private_service_connection {
    name                           = "pep-cosmos-service-connection"
    private_connection_resource_id = azurerm_cosmosdb_account.cosmos.id
    is_manual_connection           = false
    subresource_names              = ["Sql"]
  }

  private_dns_zone_group {
    name                 = "cosmos"
    private_dns_zone_ids = [azurerm_private_dns_zone.cosmos_dns.id]
  }
}

resource "azurerm_private_dns_zone" "cosmos_dns" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "cosmos_dns_link" {
  name                  = "cosmos-dns-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.cosmos_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_cosmosdb_sql_role_definition" "role_definition" {
  name                = "CosmosDBDataContributor"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.cosmos.name
  type                = "CustomRole"
  assignable_scopes   = [azurerm_cosmosdb_account.cosmos.id]

  permissions {
    data_actions = [
      "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/readChangeFeed",
      "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/executeQuery",
      "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/create",
      "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/upsert",
      "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/read",
      "Microsoft.DocumentDB/databaseAccounts/readMetadata"
    ]
  }
}

resource "azurerm_cosmosdb_sql_role_assignment" "consent_api_service" {
  resource_group_name = azurerm_resource_group.rg.name
  scope               = azurerm_cosmosdb_account.cosmos.id
  account_name        = azurerm_cosmosdb_account.cosmos.name
  role_definition_id  = azurerm_cosmosdb_sql_role_definition.role_definition.id
  principal_id        = azurerm_linux_web_app.webapp.identity[0].principal_id
}