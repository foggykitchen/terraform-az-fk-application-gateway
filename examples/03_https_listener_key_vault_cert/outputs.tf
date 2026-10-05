output "application_gateway_id" { value = module.application_gateway.application_gateway_id }
output "vnet_id" { value = module.vnet.vnet_id }
output "gateway_subnet_id" { value = module.vnet.subnet_ids["app_gateway"] }
output "public_ip_id" { value = module.public_ip.id }
output "public_ip_address" { value = module.public_ip.ip_address }
output "managed_identity_id" { value = module.managed_identity.id }
output "key_vault_id" { value = module.key_vault.key_vault_id }
output "certificate_versionless_secret_id" {
  value     = azurerm_key_vault_certificate.application_gateway.versionless_secret_id
  sensitive = true
}
