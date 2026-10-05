module "application_gateway" {
  source = "../.."

  name                = "fk-appgw-https"
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name
  location            = azurerm_resource_group.foggykitchen_rg.location
  gateway_subnet_id   = module.vnet.subnet_ids["app_gateway"]
  public_ip_id        = module.public_ip.id
  identity_ids        = [module.managed_identity.id]

  ssl_certificates = {
    site = { key_vault_secret_id = azurerm_key_vault_certificate.application_gateway.versionless_secret_id }
  }
  frontend_ports        = { https = { port = 443 } }
  backend_address_pools = { web = { fqdns = ["example.com"] } }
  probes                = { web = { protocol = "Https", path = "/", host = "example.com" } }
  backend_http_settings = { web = { port = 443, protocol = "Https", probe_key = "web", host_name = "example.com" } }
  http_listeners        = { https = { frontend_port_key = "https", protocol = "Https", ssl_certificate_key = "site" } }
  request_routing_rules = { web = { priority = 100, rule_type = "Basic", http_listener_key = "https", backend_address_pool_key = "web", backend_http_settings_key = "web" } }
}
