output "application_gateway_id" {
  description = "Application Gateway resource ID."
  value       = azurerm_application_gateway.this.id
}

output "application_gateway_name" {
  description = "Application Gateway name."
  value       = azurerm_application_gateway.this.name
}

output "backend_address_pool_ids" {
  description = "Backend pool IDs keyed by resolved pool name."
  value       = { for pool in azurerm_application_gateway.this.backend_address_pool : pool.name => pool.id }
}

output "frontend_ip_configuration_ids" {
  description = "Frontend IP configuration IDs keyed by resolved name."
  value       = { for frontend in azurerm_application_gateway.this.frontend_ip_configuration : frontend.name => frontend.id }
}

output "private_link_configuration_names" {
  description = "Private Link configuration names keyed by caller logical key."
  value       = local.private_link_configuration_names
}

output "private_link_service_ids" {
  description = "Derived Azure-managed Private Link Service resource IDs keyed by caller logical key. AzureRM does not export these generated service IDs directly."
  value = {
    for key, name in local.private_link_configuration_names : key => format(
      "/subscriptions/%s/resourceGroups/%s/providers/Microsoft.Network/privateLinkServices/_e41f87a2_%s_%s",
      split("/", var.gateway_subnet_id)[2],
      var.resource_group_name,
      var.name,
      name
    )
  }
}

output "http_listener_ids" {
  description = "HTTP listener IDs keyed by resolved name."
  value       = { for listener in azurerm_application_gateway.this.http_listener : listener.name => listener.id }
}

output "request_routing_rule_ids" {
  description = "Request routing rule IDs keyed by resolved name."
  value       = { for rule in azurerm_application_gateway.this.request_routing_rule : rule.name => rule.id }
}

output "diagnostic_setting_ids" {
  description = "Diagnostic setting IDs keyed by logical name."
  value       = { for key, setting in azurerm_monitor_diagnostic_setting.this : key => setting.id }
}
