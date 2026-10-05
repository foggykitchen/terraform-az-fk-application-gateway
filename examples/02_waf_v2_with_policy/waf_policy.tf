module "waf_policy" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-waf-policy.git?ref=v0.1.0"

  name                = var.waf_policy_name
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name
  location            = azurerm_resource_group.foggykitchen_rg.location
}
