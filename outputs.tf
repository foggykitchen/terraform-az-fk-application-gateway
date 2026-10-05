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
