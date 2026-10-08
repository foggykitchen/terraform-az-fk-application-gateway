# Azure Application Gateway with Terraform/OpenTofu – Training Examples

This directory contains all progressive examples used with the **terraform-az-fk-application-gateway** module.
The examples are designed as **incremental building blocks**, starting from a public HTTP request path and gradually evolving toward WAF-protected and HTTPS architectures.

These examples are part of the **[FoggyKitchen.com training ecosystem](https://foggykitchen.com/courses)** and are used across Azure and multicloud courses focused on networking, security, and application delivery.

---

## 🧭 Example Overview

| Example | Title | Key Topics |
|:-------:|:------|:-----------|
| 01 | **Public HTTP Backend** | Standard_v2, public frontend, HTTP listener, external FQDN backend, custom probe |
| 02 | **WAF_v2 with Policy** | VNet, Public IP, WAF_v2, WAF Policy, OWASP 3.2, Prevention mode |
| 03 | **HTTPS Listener with Key Vault Certificate** | VNet, Public IP, managed identity, Key Vault, self-signed certificate, end-to-end HTTPS |

Each example builds on the **concepts** introduced in the previous one, but can be applied independently for learning and experimentation.

---

## ⚙️ How to Use

Each example directory contains:

- Terraform/OpenTofu configuration (`.tf`)
- A focused `README.md` explaining the goal of the example
- A minimal architecture centered on one Application Gateway capability
- Architecture or Azure Portal screenshots when available

To run the first example:

```bash
cd examples/01_public_http_backend
tofu init
tofu plan -var-file=/path/to/terraform.tfvars
tofu apply -var-file=/path/to/terraform.tfvars
```

You can apply examples independently, but the **recommended approach is sequential**:
01 → 02 → 03

This mirrors real-world application delivery design, where security and TLS capabilities are introduced only when required.

---

## 🧩 Design Principles

- One example = one architectural goal
- No unused or placeholder Application Gateway configuration
- Mandatory custom health probes
- Clear separation of concerns between networking, identity, certificates, WAF policy, and gateway configuration
- Explicit ownership boundaries between Application Gateway Private Link and downstream managed Private Endpoints
- Focused FoggyKitchen modules are composed where they are available
- Existing dependency IDs are explicit inputs when the example does not own those dependencies

These examples intentionally avoid:

- Full landing zones
- Opinionated enterprise frameworks
- Hidden dependencies between examples
- Production secrets or subscription-specific values in source control

---

## 🧩 Related Resources

- [FoggyKitchen Azure Application Gateway Module (terraform-az-fk-application-gateway)](../)
- [FoggyKitchen Azure VNet Module (terraform-az-fk-vnet)](https://github.com/foggykitchen/terraform-az-fk-vnet)
- [FoggyKitchen Azure Public IP Module (terraform-az-fk-public-ip)](https://github.com/foggykitchen/terraform-az-fk-public-ip)
- [FoggyKitchen Azure Managed Identity Module (terraform-az-fk-managed-identity)](https://github.com/foggykitchen/terraform-az-fk-managed-identity)
- [FoggyKitchen Azure Key Vault Module (terraform-az-fk-key-vault)](https://github.com/foggykitchen/terraform-az-fk-key-vault)
- [FoggyKitchen Azure Load Balancer Module (terraform-az-fk-loadbalancer)](https://github.com/foggykitchen/terraform-az-fk-loadbalancer)
- [End-to-end Front Door Premium with Application Gateway Private Link](https://github.com/foggykitchen/terraform-az-fk-frontdoor/tree/v0.1.0/examples/02_premium_private_link_origin)

---

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.
See [LICENSE](../LICENSE) for details.

---

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
