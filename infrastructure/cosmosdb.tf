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