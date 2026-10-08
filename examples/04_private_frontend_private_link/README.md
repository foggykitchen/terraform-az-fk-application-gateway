# Example 04: Private Frontend with Application Gateway Private Link

This example deploys the Application Gateway side of a future **Azure Front Door Premium Private Link origin** composition. It creates no Front Door profile and no standalone Private Endpoint.

---

## 🧭 Architecture Overview

```text
Future composition (Front Door is not deployed here)

Internet
  -> Azure Front Door Premium
  -> Front Door-managed Private Endpoint
  -> Azure-managed Application Gateway Private Link Service
  -> private Application Gateway frontend (10.40.0.10)
  -> private NGINX backend VM
```

The VNet uses three purpose-specific subnets: an Application Gateway subnet, a separate Private Link subnet, and a backend subnet. The Private Link subnet disables Private Link service network policies. The backend subnet uses a NAT Gateway so cloud-init can install NGINX without assigning the VM a public IP.

Screenshot placeholder (pending deployment): architecture overview.

This example creates:

- An Azure Resource Group
- One VNet and three dedicated subnets
- A backend subnet NSG
- A NAT Gateway and its Standard public IP for backend egress
- One private Linux VM running NGINX with `/health`
- A private-only Standard_v2 Application Gateway
- One private HTTP frontend, listener, health probe, backend setting, and routing rule
- One Application Gateway Private Link configuration associated with the private frontend
- The Azure-managed backing Private Link Service

---

## 🎯 Why this example exists

The example proves the private Application Gateway origin boundary needed by the future `terraform-az-fk-frontdoor` Premium Private Link example. Its `private_link_service_id`, `private_link_configuration_name`, and listener hostname outputs are the values that downstream composition consumes.

Application Gateway Private Link requires Standard_v2 or WAF_v2. Its dedicated Private Link subnet must be separate from the gateway subnet and must have Private Link service network policies disabled. The associated frontend must have an active listener. Azure currently documents dynamic allocation only for the Private Link IP configurations, exactly one primary IP configuration, a maximum of eight IP configurations, and a combined 70-character limit for the Application Gateway and Private Link configuration names.

AzureRM models the Private Link configuration but does not export the generated `Microsoft.Network/privateLinkServices` resource ID. The module therefore derives the documented Azure-managed ID:

```text
/subscriptions/{subscription-id}/resourceGroups/{resource-group}/providers/Microsoft.Network/privateLinkServices/_e41f87a2_{applicationGatewayName}_{privateLinkConfigurationName}
```

---

## 🧩 Ownership Boundary

This example owns the VNet, subnets, NSG, NAT Gateway, backend VM, Application Gateway, and its Private Link configuration. The Application Gateway module itself creates only the gateway and optional diagnostics.

It intentionally does not create Azure Front Door, a Private Endpoint, Private DNS, certificates, or public Application Gateway ingress. Azure Front Door Premium later creates its managed Private Endpoint request, which an operator must approve on the Application Gateway side.

Front Door constraints for the future composition include:

- Private Link origins require the Premium tier.
- Public and Private Link origins cannot be mixed in one origin group.
- The Application Gateway origin must be configured as a Custom origin using the listener hostname.
- Certificate subject-name validation is mandatory for Private Link-enabled HTTPS origins, so the origin hostname must match the certificate presented by Application Gateway. This HTTP infrastructure proof does not claim to validate that future TLS path.

---

## 🚀 Deployment Steps

Copy `terraform.tfvars.example`, replace the placeholder with your public SSH key, and run:

```bash
cp terraform.tfvars.example terraform.tfvars
tofu init
tofu plan -var-file=terraform.tfvars
tofu apply -var-file=terraform.tfvars
```

Before a private-only v2 gateway deployment, verify the target subscription's current Application Gateway network-isolation prerequisites and required feature registrations. Application Gateway, NAT Gateway, and the VM are billable resources.

---

## 🖼️ Azure Portal View

Screenshot placeholder (pending deployment): resource group overview.

Screenshot placeholder (pending deployment): private Application Gateway frontend and listener.

Screenshot placeholder (pending deployment): Application Gateway Private Link configuration.

Screenshot placeholder (pending future Front Door composition): pending managed Private Endpoint connection.

---

## ✅ Future Front Door Test Procedure

After a separate Front Door Premium deployment consumes this example's outputs, locate and approve its managed Private Endpoint request:

```bash
APPGW_ID="$(tofu output -raw application_gateway_id)"

az network private-endpoint-connection list \
  --id "$APPGW_ID" \
  --query "[?properties.privateLinkServiceConnectionState.status=='Pending'].{id:id,name:name,description:properties.privateLinkServiceConnectionState.description}" \
  --output table

CONNECTION_ID="<pending-connection-resource-id>"

az network private-endpoint-connection approve \
  --id "$CONNECTION_ID" \
  --description "Approved for Azure Front Door Premium"

az network private-endpoint-connection show \
  --id "$CONNECTION_ID" \
  --query "properties.privateLinkServiceConnectionState.status" \
  --output tsv

curl -I "https://<front-door-endpoint-hostname>/"
```

The expected connection status is `Approved`. Allow several minutes for Front Door's managed connectivity to converge before testing. These commands describe the future integration test; Front Door is not deployed or tested by this repository.

---

## Provider Notes

The example retains the repository constraint `azurerm >= 3.100.0, < 5.0.0`. The required Application Gateway `private_link_configuration`, nested IP fields, and frontend association field exist at the 3.100.0 floor. Dependency modules are pinned to the exact current releases verified through the FoggyKitchen catalog: VNet `v0.1.2`, NSG `v1.0.1`, NAT Gateway `v1.1.1`, and compute `v0.4.1`.

---

## 🧹 Cleanup

Destroy the example when it is no longer needed:

```bash
tofu destroy -var-file=terraform.tfvars
```

If a future Front Door composition created a managed Private Endpoint connection, remove that composition before destroying this origin lab.

---

## 🪪 License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.
See [LICENSE](../../LICENSE) for details.

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
