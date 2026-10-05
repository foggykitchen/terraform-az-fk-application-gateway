data "azurerm_client_config" "current" {}

locals {
  key_vault_name = "fk-appgw-${substr(md5(data.azurerm_client_config.current.subscription_id), 0, 8)}"
}

module "key_vault" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-key-vault.git?ref=v0.1.0"

  key_vault_name             = local.key_vault_name
  resource_group_name        = azurerm_resource_group.foggykitchen_rg.name
  location                   = azurerm_resource_group.foggykitchen_rg.location
  rbac_authorization_enabled = false

  access_policies = [
    {
      object_id               = data.azurerm_client_config.current.object_id
      certificate_permissions = ["Create", "Delete", "Get", "List", "Purge"]
      secret_permissions      = ["Get", "List", "Set"]
    },
    {
      object_id          = module.managed_identity.principal_id
      secret_permissions = ["Get", "List"]
    }
  ]
}

resource "azurerm_key_vault_certificate" "application_gateway" {
  name         = "fk-appgw-https-cert"
  key_vault_id = module.key_vault.key_vault_id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      extended_key_usage = ["1.3.6.1.5.5.7.3.1"]
      key_usage = [
        "digitalSignature",
        "keyEncipherment",
      ]
      subject            = "CN=fk-appgw-https.example.com"
      validity_in_months = 12
    }
  }
}
