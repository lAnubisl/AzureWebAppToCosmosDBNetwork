output "webapp_name" {
  value = azurerm_linux_web_app.webapp.name
}

output "docker_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "docker_registry_username" {
  value = azurerm_container_registry_token.acr_writer_token.name
}

output "docker_registry_password" {
  value     = azurerm_container_registry_token_password.acr_writer_token_password.password1[0].value
  sensitive = true
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "stage_slot_url" {
  value = "https://${azurerm_linux_web_app.webapp.name}-${azurerm_linux_web_app_slot.webapp_slot.name}.azurewebsites.net"
}