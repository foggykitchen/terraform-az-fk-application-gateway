module "vnet" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-vnet.git?ref=v0.1.2"

  name                = "fk-appgw-pl-vnet"
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name
  location            = azurerm_resource_group.foggykitchen_rg.location
  address_space       = ["10.40.0.0/16"]

  subnets = {
    app_gateway = { address_prefixes = ["10.40.0.0/24"] }
    private_link = {
      address_prefixes                              = ["10.40.1.0/24"]
      private_link_service_network_policies_enabled = false
    }
    backend = { address_prefixes = ["10.40.2.0/24"] }
  }
}
