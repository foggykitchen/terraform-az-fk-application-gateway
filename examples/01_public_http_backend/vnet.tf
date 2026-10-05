module "vnet" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-vnet.git?ref=v0.1.2"

  name                = "fk-appgw-http-vnet"
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name
  location            = azurerm_resource_group.foggykitchen_rg.location
  address_space       = var.vnet_address_space

  subnets = {
    app_gateway = {
      address_prefixes = [var.gateway_subnet_address_prefix]
    }
  }
}
