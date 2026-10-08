# terraform-az-fk-application-gateway

This repository contains a reusable **Terraform / OpenTofu module** and progressive examples for deploying **Azure Application Gateway** resources — starting from a public HTTP request path and evolving toward WAF-protected and HTTPS architectures.

It is part of the **[FoggyKitchen.com training ecosystem](https://foggykitchen.com/courses)** and is designed as a **clean, composable application delivery layer** that builds on top of an existing Azure networking foundation.

Support expectations are documented in [SUPPORT.md](SUPPORT.md).

---

## Used By

This module is designed to be used as a building block by the higher-level [FoggyKitchen Landing Zone Orchestrator](https://github.com/foggykitchen/foggykitchen-landing-zone-orchestrator), where focused Azure modules are composed into complete landing-zone and application delivery patterns.

## 🎯 Purpose

The goal of this module is to provide a **clear, educational, and architecture-aware reference implementation** for Azure Application Gateway:

- Focused on **Standard_v2 and WAF_v2 Application Gateway**
- Explicit frontend, listener, routing, backend, and health-probe configuration
- Public and private frontend support
- Basic and path-based request routing
- Designed to integrate cleanly with:
  - Azure Virtual Networks and dedicated subnets
  - Standard Public IP addresses
  - Azure Web Application Firewall Policy
  - Azure Key Vault certificates
  - User-assigned managed identities
  - Log Analytics workspaces

This is **not** a full landing zone or opinionated application platform.
It is a **learning-first, building-block module**.

---

## ✨ What the module does

Depending on configuration and example used, the module can create:

- One Standard_v2 or WAF_v2 Application Gateway
- Fixed-capacity or autoscaled gateway capacity
- Public and/or private frontend IP configurations
- Optional Application Gateway Private Link configurations associated with the private frontend
- Frontend ports
- IP address, FQDN, and empty backend pools for separately managed VM/VMSS attachments
- Mandatory custom HTTP or HTTPS health probes
- Backend HTTP settings
- HTTP and HTTPS listeners
- Basic request-routing rules
- Path-based routing rules and URL path maps
- Key Vault-referenced or inline SSL certificates
- Optional inline WAF configuration
- Optional Azure Monitor diagnostic settings
- Optional availability-zone placement

The module intentionally does **not** create:

- Resource Groups
- Virtual Networks, subnets, route tables, or Network Security Groups
- Public IP resources
- Azure Web Application Firewall Policy resources
- Backend Virtual Machines, Virtual Machine Scale Sets, or application services
- Key Vault, certificates, managed identities, or RBAC assignments
- Log Analytics workspaces
- Private Endpoints, including the Azure Front Door-managed Private Endpoint

Each of those concerns belongs in its **own dedicated module**.

---

## 📂 Repository Structure

```text
terraform-az-fk-application-gateway/
├── examples/
│   ├── 01_public_http_backend/
│   ├── 02_waf_v2_with_policy/
│   ├── 03_https_listener_key_vault_cert/
│   └── README.md
├── main.tf
├── inputs.tf
├── outputs.tf
├── versions.tf
├── SUPPORT.md
├── LICENSE
└── README.md
```

All examples are runnable learning artifacts and introduce Application Gateway capabilities progressively.

---

## 🚀 Example Usage

```hcl
module "application_gateway" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-application-gateway.git?ref=v0.1.0"

  name                = "fk-appgw"
  resource_group_name = "fk-rg"
  location            = "westeurope"
  gateway_subnet_id   = module.vnet.subnet_ids["app_gateway"]
  public_ip_id        = module.public_ip.id

  frontend_ports = {
    http = { port = 80 }
  }

  backend_address_pools = {
    web = { fqdns = ["app.example.com"] }
  }

  probes = {
    web = {
      protocol = "Http"
      path     = "/health"
      host     = "app.example.com"
    }
  }

  backend_http_settings = {
    web = {
      port      = 80
      protocol  = "Http"
      probe_key = "web"
      host_name = "app.example.com"
    }
  }

  http_listeners = {
    http = {
      frontend_port_key = "http"
      protocol          = "Http"
    }
  }

  request_routing_rules = {
    web = {
      priority                      = 100
      rule_type                     = "Basic"
      http_listener_key             = "http"
      backend_address_pool_key      = "web"
      backend_http_settings_key     = "web"
    }
  }
}
```

At least one public or private frontend is required. Every backend HTTP setting must reference a custom probe, and every listener and routing rule must reference existing map entries.

---

## Backend Pools for VM and VMSS Attachments

Define an empty pool when a compute module manages backend membership through a NIC association or the VMSS IP configuration:

```hcl
# Inside module "application_gateway":
backend_address_pools = {
  web = {}
}

# Inside the consuming compute module:
app_gateway_attachment = {
  backend_pool_id = module.application_gateway.backend_address_pool_ids["web"]
}
```

The pool exists before compute attaches to it. Do not also add the same NIC IP to `ip_addresses`: Azure rejects duplicate membership through an explicit address and a NIC association. IP-address and FQDN pools remain supported; at least one pool must always be defined.

AzureRM documents `ip_addresses` and `fqdns` as optional and includes an empty pool in its [Application Gateway example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway).

---

## WAF_v2 Usage

Attach an externally managed Azure Web Application Firewall Policy by setting the WAF_v2 SKU and passing its resource ID:

```hcl
module "application_gateway" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-application-gateway.git?ref=v0.1.0"

  name                = "fk-appgw-waf"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  gateway_subnet_id   = module.vnet.subnet_ids["app_gateway"]
  public_ip_id        = module.public_ip.id
  sku_name            = "WAF_v2"
  firewall_policy_id  = azurerm_web_application_firewall_policy.this.id

  # Frontend, backend, probe, listener, and routing maps omitted for brevity.
}
```

`firewall_policy_id` and `inline_waf_configuration` are mutually exclusive. Both require `sku_name = "WAF_v2"`.

---

## HTTPS and Key Vault Usage

For a Key Vault-backed HTTPS listener, pass a versionless certificate secret ID and attach an existing user-assigned managed identity to the gateway:

```hcl
ssl_certificates = {
  site = {
    key_vault_secret_id = var.certificate_secret_id
  }
}

identity_ids = [var.identity_id]

frontend_ports = {
  https = { port = 443 }
}

http_listeners = {
  https = {
    frontend_port_key   = "https"
    protocol            = "Https"
    ssl_certificate_key = "site"
  }
}
```

The caller is responsible for granting the identity permission to read the certificate secret from Key Vault.

---

## 📥 Module Inputs

| Variable | Type | Required | Description |
|---|---|:---:|---|
| `name` | `string` | ✅ | Application Gateway name |
| `resource_group_name` | `string` | ✅ | Resource group containing the gateway |
| `location` | `string` | ✅ | Azure region |
| `gateway_subnet_id` | `string` | ✅ | Dedicated Application Gateway subnet ID |
| `sku_name` | `string` | ❌ | `Standard_v2` or `WAF_v2` |
| `capacity` | `number` | ❌ | Fixed capacity, mutually exclusive with autoscaling |
| `autoscale_configuration` | `object` | ❌ | Minimum and optional maximum autoscale capacity |
| `public_ip_id` | `string` | ❌ | Existing Standard public IP ID |
| `private_frontend` | `object` | ❌ | Private frontend subnet and IP configuration |
| `private_link_configurations` | `map(object)` | ❌ | Application Gateway Private Link configurations and nested dynamic IP configurations, keyed by logical name |
| `frontend_ports` | `map(object)` | ✅ | Frontend ports keyed by logical name |
| `backend_address_pools` | `map(object)` | ✅ | IP address, FQDN, or empty backend pools for VM/VMSS attachments |
| `backend_http_settings` | `map(object)` | ✅ | Backend HTTP settings with probe references |
| `probes` | `map(object)` | ✅ | Custom HTTP or HTTPS health probes |
| `http_listeners` | `map(object)` | ✅ | HTTP or HTTPS listeners |
| `request_routing_rules` | `map(object)` | ✅ | Basic or path-based routing rules |
| `url_path_maps` | `map(object)` | ❌ | URL path maps and path rules |
| `ssl_certificates` | `map(object)` | ❌ | Key Vault or inline PFX certificates |
| `identity_ids` | `list(string)` | ❌ | Existing user-assigned managed identity IDs |
| `firewall_policy_id` | `string` | ❌ | Existing WAF Policy ID |
| `inline_waf_configuration` | `object` | ❌ | Basic inline WAF configuration |
| `diagnostic_settings` | `map(object)` | ❌ | Log Analytics diagnostic settings |
| `zones` | `list(string)` | ❌ | Optional availability zones |
| `http2_enabled` | `bool` | ❌ | Enable HTTP/2 |
| `tags` | `map(string)` | ❌ | Resource tags |

---

## 📤 Outputs

| Output | Description |
|---|---|
| `application_gateway_id` | Application Gateway resource ID |
| `application_gateway_name` | Application Gateway name |
| `backend_address_pool_ids` | Backend pool IDs keyed by resolved name |
| `frontend_ip_configuration_ids` | Frontend IP configuration IDs keyed by resolved name |
| `private_link_configuration_names` | Private Link configuration names keyed by logical name |
| `private_link_service_ids` | Derived Azure-managed Private Link Service IDs keyed by logical name |
| `http_listener_ids` | HTTP listener IDs keyed by resolved name |
| `request_routing_rule_ids` | Request-routing rule IDs keyed by resolved name |
| `diagnostic_setting_ids` | Diagnostic setting IDs keyed by logical name |

---

## 🧠 Design Philosophy

- Application Gateway configuration remains **explicit and reviewable**
- Health probes are mandatory and modeled independently from backend settings
- Networking, Public IP, identity, WAF Policy, certificates, and monitoring destinations remain separate concerns
- Public and private entry points are intentional architectural choices
- Private Link configuration is owned here; its dedicated subnet, consumers, and managed Private Endpoints remain external composition concerns
- Map-based inputs make relationships between listeners, rules, pools, settings, and probes visible
- Outputs are first-class citizens for downstream composition

Application Gateway Private Link requires Standard_v2 or WAF_v2, a dedicated Private Link subnet separate from the gateway subnet, disabled Private Link service network policies on that subnet, and a listener on the associated frontend. The current Azure service documentation supports only dynamically allocated Private Link IP configurations, requires exactly one primary configuration, permits up to eight IP configurations, and limits the combined Application Gateway and Private Link configuration names to 70 characters.

Azure creates the backing `Microsoft.Network/privateLinkServices` resource. AzureRM exposes the configuration object but not that generated service resource ID, so `private_link_service_ids` deterministically derives Azure's documented `_e41f87a2_{applicationGatewayName}_{privateLinkConfigurationName}` ID for downstream consumers such as Azure Front Door Premium.

For a complete, deployable Front Door Premium → managed Private Endpoint → Application Gateway Private Link → private NGINX flow, use [`terraform-az-fk-frontdoor/examples/02_premium_private_link_origin`](https://github.com/foggykitchen/terraform-az-fk-frontdoor/tree/v0.1.0/examples/02_premium_private_link_origin). The end-to-end example belongs to the consuming Front Door module so the managed Private Endpoint lifecycle and approval workflow remain demonstrated in one canonical place.

---

## 🧩 Related Modules & Training

- [terraform-az-fk-vnet](https://github.com/foggykitchen/terraform-az-fk-vnet)
- [terraform-az-fk-public-ip](https://github.com/foggykitchen/terraform-az-fk-public-ip)
- [terraform-az-fk-managed-identity](https://github.com/foggykitchen/terraform-az-fk-managed-identity)
- [terraform-az-fk-key-vault](https://github.com/foggykitchen/terraform-az-fk-key-vault)
- [terraform-az-fk-loadbalancer](https://github.com/foggykitchen/terraform-az-fk-loadbalancer)
- [terraform-az-fk-private-endpoint](https://github.com/foggykitchen/terraform-az-fk-private-endpoint)

See [examples](examples/README.md) for progressive, runnable Application Gateway scenarios.

---

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.
See [LICENSE](LICENSE) for details.

---

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
