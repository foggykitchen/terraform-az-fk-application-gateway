module "application_gateway" {
  source = "../.."

  name                = "fk-appgw-http"
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name
  location            = azurerm_resource_group.foggykitchen_rg.location
  gateway_subnet_id   = module.vnet.subnet_ids["app_gateway"]
  public_ip_id        = module.public_ip.id

  frontend_ports        = { http = { port = 80 } }
  backend_address_pools = { web = { fqdns = ["example.com"] } }
  probes                = { web = { protocol = "Http", path = "/", host = "example.com" } }
  backend_http_settings = { web = { port = 80, protocol = "Http", probe_key = "web", host_name = "example.com" } }
  http_listeners        = { http = { frontend_port_key = "http", protocol = "Http" } }
  request_routing_rules = { web = { priority = 100, rule_type = "Basic", http_listener_key = "http", backend_address_pool_key = "web", backend_http_settings_key = "web" } }
}
