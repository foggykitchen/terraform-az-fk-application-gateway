module "nat_gateway" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-natgw.git?ref=v1.1.1"

  name                = "fk-appgw-pl-natgw"
  public_ip_name      = "fk-appgw-pl-natgw-pip"
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name
  location            = azurerm_resource_group.foggykitchen_rg.location
  create_public_ip    = true
  subnet_associations = { backend = { subnet_id = module.vnet.subnet_ids["backend"] } }
}
