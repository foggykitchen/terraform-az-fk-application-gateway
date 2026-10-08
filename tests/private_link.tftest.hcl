mock_provider "azurerm" {}

variables {
  name                = "fk-test-appgw"
  resource_group_name = "fk-test-rg"
  location            = "westeurope"
  gateway_subnet_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/fk-test-rg/providers/Microsoft.Network/virtualNetworks/test/subnets/gateway"
  private_frontend = {
    subnet_id                     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/fk-test-rg/providers/Microsoft.Network/virtualNetworks/test/subnets/gateway"
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.0.10"
  }
  frontend_ports        = { http = { port = 80 } }
  backend_address_pools = { web = {} }
  probes                = { web = { protocol = "Http", path = "/health", host = "localhost" } }
  backend_http_settings = { web = { port = 80, protocol = "Http", probe_key = "web" } }
  http_listeners        = { http = { frontend_type = "private", frontend_port_key = "http", protocol = "Http" } }
  request_routing_rules = { web = { priority = 100, rule_type = "Basic", http_listener_key = "http", backend_address_pool_key = "web", backend_http_settings_key = "web" } }
}

run "no_private_link_configuration" {
  command = plan

  assert {
    condition     = length(azurerm_application_gateway.this.private_link_configuration) == 0
    error_message = "The default empty input must not create Private Link configuration blocks."
  }
}

run "private_frontend_private_link" {
  command = plan
  variables {
    private_frontend = {
      subnet_id                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/fk-test-rg/providers/Microsoft.Network/virtualNetworks/test/subnets/gateway"
      private_ip_address_allocation  = "Static"
      private_ip_address             = "10.0.0.10"
      private_link_configuration_key = "frontdoor"
    }
    private_link_configurations = {
      frontdoor = {
        name = "frontdoor"
        ip_configurations = {
          primary = {
            subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/fk-test-rg/providers/Microsoft.Network/virtualNetworks/test/subnets/private-link"
            primary   = true
          }
          scale = {
            subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/fk-test-rg/providers/Microsoft.Network/virtualNetworks/test/subnets/private-link"
            primary   = false
          }
        }
      }
    }
  }

  assert {
    condition     = length(azurerm_application_gateway.this.private_link_configuration) == 1 && length(one(azurerm_application_gateway.this.private_link_configuration).ip_configuration) == 2
    error_message = "The gateway must render the Private Link configuration and all nested IP configurations."
  }

  assert {
    condition     = one([for frontend in azurerm_application_gateway.this.frontend_ip_configuration : frontend.private_link_configuration_name if frontend.name == "frontend-private"]) == "frontdoor"
    error_message = "The private frontend must reference the resolved Private Link configuration name."
  }
}

run "invalid_private_link_reference" {
  command = plan
  variables {
    private_frontend = {
      subnet_id                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/fk-test-rg/providers/Microsoft.Network/virtualNetworks/test/subnets/gateway"
      private_ip_address_allocation  = "Static"
      private_ip_address             = "10.0.0.10"
      private_link_configuration_key = "missing"
    }
  }
  expect_failures = [azurerm_application_gateway.this]
}

run "invalid_primary_count" {
  command = plan
  variables {
    private_link_configurations = {
      frontdoor = {
        ip_configurations = {
          first  = { subnet_id = "test", primary = false }
          second = { subnet_id = "test", primary = false }
        }
      }
    }
  }
  expect_failures = [var.private_link_configurations]
}

run "dynamic_address_must_be_implicit" {
  command = plan
  variables {
    private_link_configurations = {
      frontdoor = {
        ip_configurations = {
          primary = { subnet_id = "test", primary = true, private_ip_address = "10.0.1.4" }
        }
      }
    }
  }
  expect_failures = [var.private_link_configurations]
}

run "static_private_link_ip_is_rejected" {
  command = plan
  variables {
    private_link_configurations = {
      frontdoor = {
        ip_configurations = {
          primary = { subnet_id = "test", primary = true, private_ip_address_allocation = "Static", private_ip_address = "10.0.1.4" }
        }
      }
    }
  }
  expect_failures = [var.private_link_configurations]
}

run "derived_private_link_service_id" {
  command = plan

  override_resource {
    target = azurerm_application_gateway.this
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/fk-test-rg/providers/Microsoft.Network/applicationGateways/fk-test-appgw"
    }
  }

  variables {
    private_frontend = {
      subnet_id                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/fk-test-rg/providers/Microsoft.Network/virtualNetworks/test/subnets/gateway"
      private_ip_address_allocation  = "Static"
      private_ip_address             = "10.0.0.10"
      private_link_configuration_key = "frontdoor"
    }
    private_link_configurations = {
      frontdoor = {
        ip_configurations = {
          primary = { subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/fk-test-rg/providers/Microsoft.Network/virtualNetworks/test/subnets/private-link", primary = true }
        }
      }
    }
  }

  assert {
    condition     = output.private_link_service_ids["frontdoor"] == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/fk-test-rg/providers/Microsoft.Network/privateLinkServices/_e41f87a2_fk-test-appgw_frontdoor"
    error_message = "The derived Azure-managed Private Link Service ID must follow Azure's documented naming convention."
  }
}
