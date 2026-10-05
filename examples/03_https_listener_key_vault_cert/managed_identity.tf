module "managed_identity" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-managed-identity.git?ref=v0.1.0"

  name                = "fk-appgw-https-identity"
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name
  location            = azurerm_resource_group.foggykitchen_rg.location
}
