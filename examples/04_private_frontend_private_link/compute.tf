module "nginx" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-compute.git?ref=v0.4.1"

  name                = "fk-appgw-pl-nginx"
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name
  location            = azurerm_resource_group.foggykitchen_rg.location
  deployment_mode     = "vm"
  subnet_id           = module.vnet.subnet_ids["backend"]
  admin_username      = var.admin_username
  ssh_public_key      = var.ssh_public_key
  custom_data         = base64encode(templatefile("${path.module}/cloud-init-nginx.yaml.tftpl", {}))
  app_gateway_attachment = {
    backend_pool_id = module.application_gateway.backend_address_pool_ids["nginx"]
  }

  depends_on = [module.backend_nsg, module.nat_gateway]
}
