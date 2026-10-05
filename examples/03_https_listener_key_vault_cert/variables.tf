variable "resource_group_name" { type = string }
variable "location" {
  type    = string
  default = "westeurope"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "Address space of the example VNet."
  default     = ["10.30.0.0/16"]
}

variable "gateway_subnet_address_prefix" {
  type        = string
  description = "Address prefix of the dedicated Application Gateway subnet."
  default     = "10.30.0.0/24"
}
