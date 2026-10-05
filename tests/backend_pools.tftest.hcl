mock_provider "azurerm" {}

variables {
  name                  = "fk-test-appgw"
  resource_group_name   = "fk-test-rg"
  location              = "westeurope"
  gateway_subnet_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/fk-test-rg/providers/Microsoft.Network/virtualNetworks/test/subnets/gateway"
  public_ip_id          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/fk-test-rg/providers/Microsoft.Network/publicIPAddresses/test"
  frontend_ports        = { http = { port = 80 } }
  backend_address_pools = { web = {} }
  probes                = { web = { protocol = "Http", path = "/", host = "localhost" } }
  backend_http_settings = { web = { port = 80, protocol = "Http", probe_key = "web" } }
  http_listeners        = { http = { frontend_port_key = "http", protocol = "Http" } }
  request_routing_rules = { web = { priority = 100, rule_type = "Basic", http_listener_key = "http", backend_address_pool_key = "web", backend_http_settings_key = "web" } }
}

run "empty_pool_for_compute_attachments" {
  command = plan
  assert {
    condition = length(azurerm_application_gateway.this.backend_address_pool) == 1 && alltrue([
      for pool in azurerm_application_gateway.this.backend_address_pool :
      pool.name == "web" && length(pool.ip_addresses) == 0 && length(pool.fqdns) == 0
    ])
    error_message = "The gateway must accept a named empty backend pool for NIC/VMSS membership."
  }
}

run "explicit_addresses_remain_supported" {
  command = plan
  variables {
    backend_address_pools = { web = { ip_addresses = ["10.70.1.4"], fqdns = ["app.example.com"] } }
  }
  assert {
    condition = alltrue([
      for pool in azurerm_application_gateway.this.backend_address_pool :
      contains(pool.ip_addresses, "10.70.1.4") && contains(pool.fqdns, "app.example.com")
    ])
    error_message = "Existing explicit IP and FQDN membership must remain supported."
  }
}

run "at_least_one_pool_required" {
  command = plan
  variables {
    backend_address_pools = {}
  }
  expect_failures = [var.backend_address_pools]
}
