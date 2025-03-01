terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.19.0"
    }
  }
  required_version = ">= 1.9.0"
  backend "azurerm" {
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "rm-webapp-cosmosdb"
  location = "westeurope"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-webapp-cosmosdb"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Subnet for Web App VNet integration
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

/*
resource "azurerm_app_service_virtual_network_swift_connection" "vnet_integration" {
  app_service_id = azurerm_linux_web_app.webapp.id
  subnet_id      = azurerm_subnet.webapp_subnet.id
}
*/
# Subnet for Cosmos DB private endpoint; disable network policies to allow private endpoint connections
resource "azurerm_subnet" "cosmos_subnet" {
  name                                          = "cosmos-subnet"
  resource_group_name                           = azurerm_resource_group.rg.name
  virtual_network_name                          = azurerm_virtual_network.vnet.name
  address_prefixes                              = ["10.0.2.0/24"]
  private_link_service_network_policies_enabled = false
}

#############################
# App Service Plan & Web App
#############################

# Linux App Service Plan for containerized apps
resource "azurerm_service_plan" "asp" {
  name                = "serviceplan-asdskfrtdf"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "B1"
}

# Web App for Containers – replace <container_image> with your actual container image reference.
resource "azurerm_linux_web_app" "webapp" {
  name                = "webapp-sdflretbvsdfr"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.asp.id

  site_config {
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
      site_config[0].application_stack 
    ]
  }
}

#############################
# Cosmos DB (Serverless) Setup
#############################

# Create Cosmos DB account with serverless capability and disable public access.
resource "azurerm_cosmosdb_account" "cosmos" {
  name                = "cosmos-asgbdsfgegdfg"
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
  name                = "data"
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

# Create a Private Endpoint for the Cosmos DB account.
resource "azurerm_private_endpoint" "cosmos_pe" {
  name                = "pep-cosmosdb-asddsdfgkjdsfg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.cosmos_subnet.id

  private_service_connection {
    name                           = "pep-conn-cosmos-connection-sdafgsdakteq"
    private_connection_resource_id = azurerm_cosmosdb_account.cosmos.id
    is_manual_connection           = false
    subresource_names              = ["Sql"]
  }

  private_dns_zone_group {
    name                 = "cosmos"
    private_dns_zone_ids = [azurerm_private_dns_zone.cosmos_dns.id]
  }
}

# Create a Private DNS Zone for Cosmos DB (for SQL API the zone is "privatelink.documents.azure.com").
resource "azurerm_private_dns_zone" "cosmos_dns" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
}

# Link the Private DNS Zone to the virtual network.
resource "azurerm_private_dns_zone_virtual_network_link" "cosmos_dns_link" {
  name                  = "cosmos-dns-link-asdasdreyjnfg"
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