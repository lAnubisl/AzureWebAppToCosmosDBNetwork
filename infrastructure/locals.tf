locals {
  unique_name = random_string.random.result

  # Resource name locals built from the unique_name prefix (match existing naming patterns)
  resource_group_name            = "rg-${local.unique_name}"
  cosmosdb_account_name          = "cosmosdb-${local.unique_name}"
  cosmosdb_database_name         = "db-${local.unique_name}"
  cosmosdb_private_endpoint_name = "pe-cosmosdb-${local.unique_name}"
  docker_registry_name           = "acr${local.unique_name}"
  virtual_network_name           = "vnet-${local.unique_name}"
  service_plan_name              = "sp-${local.unique_name}"
  webapp_name                    = "webapp-${local.unique_name}"
}