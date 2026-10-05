output "application_gateway_id" { value = module.application_gateway.application_gateway_id }
output "vnet_id" { value = module.vnet.vnet_id }
output "gateway_subnet_id" { value = module.vnet.subnet_ids["app_gateway"] }
output "public_ip_id" { value = module.public_ip.id }
output "public_ip_address" { value = module.public_ip.ip_address }

output "waf_policy_id" {
  description = "ID of the temporary example-owned WAF Policy."
  value       = azurerm_web_application_firewall_policy.this.id
}
