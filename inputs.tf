variable "name" {
  description = "Application Gateway name."
  type        = string
  validation {
    condition     = trimspace(var.name) != ""
    error_message = "name must not be empty."
  }
}

variable "resource_group_name" {
  description = "Resource group containing the Application Gateway."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "gateway_subnet_id" {
  description = "Dedicated Application Gateway subnet ID."
  type        = string
}

variable "sku_name" {
  description = "Application Gateway v2 SKU name: Standard_v2 or WAF_v2."
  type        = string
  default     = "Standard_v2"
  validation {
    condition     = contains(["Standard_v2", "WAF_v2"], var.sku_name)
    error_message = "sku_name must be Standard_v2 or WAF_v2."
  }
}

variable "capacity" {
  description = "Fixed v2 instance capacity. Mutually exclusive with autoscale_configuration."
  type        = number
  default     = null
  validation {
    condition     = var.capacity == null || (var.capacity >= 1 && var.capacity <= 125)
    error_message = "capacity must be null or between 1 and 125."
  }
}

variable "autoscale_configuration" {
  description = "Optional v2 autoscaling configuration."
  type = object({
    min_capacity = number
    max_capacity = optional(number)
  })
  default = {
    min_capacity = 0
    max_capacity = 10
  }
}

variable "public_ip_id" {
  description = "Existing Public IP resource ID for the public frontend. The module never creates it."
  type        = string
  default     = null
}

variable "private_frontend" {
  description = "Optional private frontend on the gateway subnet or another eligible subnet."
  type = object({
    subnet_id                     = string
    private_ip_address_allocation = optional(string, "Dynamic")
    private_ip_address            = optional(string)
  })
  default = null
}

variable "frontend_ports" {
  description = "Frontend ports keyed by logical name."
  type = map(object({
    name = optional(string)
    port = number
  }))
  validation {
    condition     = length(var.frontend_ports) > 0 && alltrue([for port in values(var.frontend_ports) : port.port >= 1 && port.port <= 65535])
    error_message = "At least one frontend port is required and every port must be between 1 and 65535."
  }
}

variable "backend_address_pools" {
  description = "Backend pools keyed by logical name. Each pool accepts IP addresses, FQDNs, or both."
  type = map(object({
    name         = optional(string)
    ip_addresses = optional(list(string), [])
    fqdns        = optional(list(string), [])
  }))
  validation {
    condition     = length(var.backend_address_pools) > 0 && alltrue([for pool in values(var.backend_address_pools) : length(pool.ip_addresses) + length(pool.fqdns) > 0])
    error_message = "At least one backend pool is required and every pool must contain an IP address or FQDN."
  }
}

variable "backend_http_settings" {
  description = "Backend HTTP settings keyed by logical name. probe_key must reference a mandatory probe."
  type = map(object({
    name                                = optional(string)
    port                                = number
    protocol                            = string
    cookie_based_affinity               = optional(string, "Disabled")
    path                                = optional(string)
    host_name                           = optional(string)
    pick_host_name_from_backend_address = optional(bool, false)
    probe_key                           = string
    request_timeout                     = optional(number, 30)
  }))
  validation {
    condition     = length(var.backend_http_settings) > 0 && alltrue([for setting in values(var.backend_http_settings) : contains(["Http", "Https"], setting.protocol)])
    error_message = "At least one backend HTTP setting is required and protocol must be Http or Https."
  }
}

variable "probes" {
  description = "Mandatory custom health probes keyed by logical name. HTTP/HTTPS probes require exactly one of host or pick_host_name_from_backend_http_settings."
  type = map(object({
    name                                      = optional(string)
    protocol                                  = string
    path                                      = optional(string)
    host                                      = optional(string)
    pick_host_name_from_backend_http_settings = optional(bool, false)
    port                                      = optional(number)
    interval                                  = optional(number, 30)
    timeout                                   = optional(number, 30)
    unhealthy_threshold                       = optional(number, 3)
    minimum_servers                           = optional(number, 0)
    match_status_codes                        = optional(list(string), ["200-399"])
  }))
  validation {
    condition     = length(var.probes) > 0 && alltrue([for probe in values(var.probes) : contains(["Http", "Https"], probe.protocol) && probe.path != null && ((probe.host != null) != probe.pick_host_name_from_backend_http_settings)])
    error_message = "At least one Http/Https probe is required; each needs a path and exactly one of host or pick_host_name_from_backend_http_settings=true."
  }
}

variable "http_listeners" {
  description = "HTTP/HTTPS listeners keyed by logical name. frontend_type selects public or private."
  type = map(object({
    name                = optional(string)
    frontend_type       = optional(string, "public")
    frontend_port_key   = string
    protocol            = string
    host_name           = optional(string)
    host_names          = optional(list(string))
    require_sni         = optional(bool, false)
    ssl_certificate_key = optional(string)
  }))
  validation {
    condition     = length(var.http_listeners) > 0 && alltrue([for listener in values(var.http_listeners) : contains(["Http", "Https"], listener.protocol) && contains(["public", "private"], listener.frontend_type)])
    error_message = "At least one listener is required; protocols are Http/Https and frontend_type is public/private."
  }
}

variable "request_routing_rules" {
  description = "Basic or PathBasedRouting rules keyed by logical name."
  type = map(object({
    name                      = optional(string)
    priority                  = number
    rule_type                 = string
    http_listener_key         = string
    backend_address_pool_key  = optional(string)
    backend_http_settings_key = optional(string)
    url_path_map_key          = optional(string)
  }))
  validation {
    condition     = length(var.request_routing_rules) > 0 && alltrue([for rule in values(var.request_routing_rules) : contains(["Basic", "PathBasedRouting"], rule.rule_type) && rule.priority >= 1 && rule.priority <= 20000])
    error_message = "At least one Basic or PathBasedRouting rule is required; priorities must be 1..20000."
  }
}

variable "url_path_maps" {
  description = "URL path maps keyed by logical name for PathBasedRouting rules."
  type = map(object({
    name                              = optional(string)
    default_backend_address_pool_key  = string
    default_backend_http_settings_key = string
    path_rules = map(object({
      name                      = optional(string)
      paths                     = list(string)
      backend_address_pool_key  = string
      backend_http_settings_key = string
    }))
  }))
  default = {}
}

variable "ssl_certificates" {
  description = "SSL certificates keyed by logical name. Prefer key_vault_secret_id; inline PFX data/password remains available for simple cases."
  type = map(object({
    name                = optional(string)
    key_vault_secret_id = optional(string)
    data                = optional(string)
    password            = optional(string)
  }))
  default   = {}
  sensitive = true
}

variable "identity_ids" {
  description = "Existing user-assigned managed identity IDs, required for Key Vault-referenced certificates."
  type        = list(string)
  default     = []
}

variable "firewall_policy_id" {
  description = "Existing Web Application Firewall Policy ID attached at gateway scope."
  type        = string
  default     = null
}

variable "inline_waf_configuration" {
  description = "Basic inline WAF fallback. Mutually exclusive with firewall_policy_id and valid only for WAF_v2."
  type = object({
    enabled                  = optional(bool, true)
    firewall_mode            = optional(string, "Prevention")
    rule_set_type            = optional(string, "OWASP")
    rule_set_version         = optional(string, "3.2")
    file_upload_limit_mb     = optional(number, 100)
    request_body_check       = optional(bool, true)
    max_request_body_size_kb = optional(number, 128)
  })
  default = null
}

variable "diagnostic_settings" {
  description = "Azure Monitor diagnostic settings keyed by logical name. Destinations are externally managed."
  type = map(object({
    name                           = optional(string)
    log_analytics_workspace_id     = string
    log_analytics_destination_type = optional(string, "Dedicated")
    log_category_groups            = optional(set(string), ["allLogs"])
    metric_categories              = optional(set(string), ["AllMetrics"])
  }))
  default = {}
}

variable "zones" {
  description = "Optional availability zones for the v2 gateway."
  type        = list(string)
  default     = null
}

variable "http2_enabled" {
  description = "Whether HTTP/2 is enabled."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags assigned to the Application Gateway."
  type        = map(string)
  default     = {}
}
