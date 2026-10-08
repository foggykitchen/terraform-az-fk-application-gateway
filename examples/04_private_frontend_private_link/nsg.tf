module "backend_nsg" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-nsg.git?ref=v1.0.1"

  name                = "fk-appgw-pl-backend-nsg"
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name
  location            = azurerm_resource_group.foggykitchen_rg.location
  subnet_associations = { backend = { subnet_id = module.vnet.subnet_ids["backend"] } }

  rules = [{
    name                       = "allow-appgw-http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "10.40.0.0/24"
    destination_address_prefix = "10.40.2.0/24"
  }]
}
