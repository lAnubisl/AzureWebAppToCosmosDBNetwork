output "webapp_name" {
  value = azurerm_linux_web_app.webapp.name
}

output "docker_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "docker_registry_username" {
  value = azurerm_container_registry.acr.admin_username
}

output "docker_registry_password" {
  value = azurerm_container_registry.acr.admin_password
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "stage_slot_url" {
  value = "https://${azurerm_linux_web_app.webapp.name}-${azurerm_linux_web_app_slot.webapp_slot.name}.azurewebsites.net"
}