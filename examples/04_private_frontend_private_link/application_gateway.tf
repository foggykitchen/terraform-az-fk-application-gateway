locals {
  listener_hostname = "appgw-origin.internal"
}

module "application_gateway" {
  source = "../.."

  name                = "fk-appgw-private-link"
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name
  location            = azurerm_resource_group.foggykitchen_rg.location
  gateway_subnet_id   = module.vnet.subnet_ids["app_gateway"]
  sku_name            = "Standard_v2"

  private_frontend = {
    subnet_id                      = module.vnet.subnet_ids["app_gateway"]
    private_ip_address_allocation  = "Static"
    private_ip_address             = "10.40.0.10"
    private_link_configuration_key = "frontdoor"
  }

  private_link_configurations = {
    frontdoor = {
      name = "frontdoor"
      ip_configurations = {
        primary = {
          name      = "primary"
          subnet_id = module.vnet.subnet_ids["private_link"]
          primary   = true
        }
      }
    }
  }

  frontend_ports        = { http = { port = 80 } }
  backend_address_pools = { nginx = {} }
  probes                = { nginx = { protocol = "Http", path = "/health", host = local.listener_hostname } }
  backend_http_settings = { nginx = { port = 80, protocol = "Http", probe_key = "nginx", host_name = local.listener_hostname } }
  http_listeners        = { private = { frontend_type = "private", frontend_port_key = "http", protocol = "Http", host_name = local.listener_hostname } }
  request_routing_rules = { nginx = { priority = 100, rule_type = "Basic", http_listener_key = "private", backend_address_pool_key = "nginx", backend_http_settings_key = "nginx" } }
}
