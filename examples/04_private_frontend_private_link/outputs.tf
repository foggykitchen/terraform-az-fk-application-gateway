output "application_gateway_id" { value = module.application_gateway.application_gateway_id }
output "private_frontend_ip" { value = "10.40.0.10" }
output "listener_hostname" { value = local.listener_hostname }
output "private_link_service_id" { value = module.application_gateway.private_link_service_ids["frontdoor"] }
output "private_link_configuration_name" { value = module.application_gateway.private_link_configuration_names["frontdoor"] }
output "backend_vm_id" { value = module.nginx.vm_id }
