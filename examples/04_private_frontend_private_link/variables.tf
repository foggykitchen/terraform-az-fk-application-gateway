variable "resource_group_name" { type = string }
variable "location" {
  type    = string
  default = "westeurope"
}
variable "admin_username" {
  type    = string
  default = "azureuser"
}
variable "ssh_public_key" {
  description = "Public SSH key for the private backend VM."
  type        = string
}
