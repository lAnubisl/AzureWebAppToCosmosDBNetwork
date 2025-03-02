variable "resource_group_name" {
  type    = string
  default = "rm-webapp-cosmosdb"
}

variable "resource_group_location" {
  type    = string
  default = "westeurope"
}

variable "virtual_network_name" {
  type    = string
  default = "vnet-webapp-cosmosdb"
}

variable "service_plan_name" {
  type    = string
  default = "serviceplan-asdskfrtdf"
}

variable "service_plan_sku" {
  type    = string
  default = "P0v3"
}

variable "webapp_name" {
  type    = string
  default = "webapp-sdflretbvsdfr"
}

variable "cosmosdb_account_name" {
  type    = string
  default = "cosmos-asgbdsfgegdfg"
}

variable "cosmosdb_database_name" {
  type    = string
  default = "data"
}

variable "cosmosdb_private_endpoint_name" {
  type    = string
  default = "pep-cosmosdb-asddsdfgkjdsfg"
}

variable "docker_registry_name" {
  type    = string
  default = "dockersafsafjkewrqwr2314"
}