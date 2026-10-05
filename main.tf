locals {
  frontend_ip_names = {
    public  = "frontend-public"
    private = "frontend-private"
  }
  frontend_port_names   = { for key, value in var.frontend_ports : key => coalesce(value.name, key) }
  backend_pool_names    = { for key, value in var.backend_address_pools : key => coalesce(value.name, key) }
  backend_setting_names = { for key, value in var.backend_http_settings : key => coalesce(value.name, key) }
  probe_names           = { for key, value in var.probes : key => coalesce(value.name, key) }
  listener_names        = { for key, value in var.http_listeners : key => coalesce(value.name, key) }
  certificate_names     = { for key, value in nonsensitive(var.ssl_certificates) : key => coalesce(value.name, key) }
  path_map_names        = { for key, value in var.url_path_maps : key => coalesce(value.name, key) }
}

resource "azurerm_application_gateway" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  firewall_policy_id  = var.firewall_policy_id
  http2_enabled       = var.http2_enabled
  zones               = var.zones
  tags                = var.tags

  sku {
    name     = var.sku_name
    tier     = var.sku_name
    capacity = var.autoscale_configuration == null ? var.capacity : null
  }

  dynamic "autoscale_configuration" {
    for_each = var.autoscale_configuration == null ? [] : [var.autoscale_configuration]
    content {
      min_capacity = autoscale_configuration.value.min_capacity
      max_capacity = autoscale_configuration.value.max_capacity
    }
  }

  gateway_ip_configuration {
    name      = "gateway-ip-configuration"
    subnet_id = var.gateway_subnet_id
  }

  dynamic "frontend_ip_configuration" {
    for_each = var.public_ip_id == null ? {} : { public = var.public_ip_id }
    content {
      name                 = local.frontend_ip_names.public
      public_ip_address_id = frontend_ip_configuration.value
    }
  }

  dynamic "frontend_ip_configuration" {
    for_each = var.private_frontend == null ? {} : { private = var.private_frontend }
    content {
      name                          = local.frontend_ip_names.private
      subnet_id                     = frontend_ip_configuration.value.subnet_id
      private_ip_address_allocation = frontend_ip_configuration.value.private_ip_address_allocation
      private_ip_address            = frontend_ip_configuration.value.private_ip_address
    }
  }

  dynamic "frontend_port" {
    for_each = var.frontend_ports
    content {
      name = local.frontend_port_names[frontend_port.key]
      port = frontend_port.value.port
    }
  }

  dynamic "backend_address_pool" {
    for_each = var.backend_address_pools
    content {
      name         = local.backend_pool_names[backend_address_pool.key]
      ip_addresses = backend_address_pool.value.ip_addresses
      fqdns        = backend_address_pool.value.fqdns
    }
  }

  dynamic "probe" {
    for_each = var.probes
    content {
      name                                      = local.probe_names[probe.key]
      protocol                                  = probe.value.protocol
      path                                      = probe.value.path
      host                                      = probe.value.host
      pick_host_name_from_backend_http_settings = probe.value.pick_host_name_from_backend_http_settings
      port                                      = probe.value.port
      interval                                  = probe.value.interval
      timeout                                   = probe.value.timeout
      unhealthy_threshold                       = probe.value.unhealthy_threshold
      minimum_servers                           = probe.value.minimum_servers
      match {
        status_code = probe.value.match_status_codes
      }
    }
  }

  dynamic "backend_http_settings" {
    for_each = var.backend_http_settings
    content {
      name                                = local.backend_setting_names[backend_http_settings.key]
      port                                = backend_http_settings.value.port
      protocol                            = backend_http_settings.value.protocol
      cookie_based_affinity               = backend_http_settings.value.cookie_based_affinity
      path                                = backend_http_settings.value.path
      host_name                           = backend_http_settings.value.host_name
      pick_host_name_from_backend_address = backend_http_settings.value.pick_host_name_from_backend_address
      probe_name                          = local.probe_names[backend_http_settings.value.probe_key]
      request_timeout                     = backend_http_settings.value.request_timeout
    }
  }

  dynamic "ssl_certificate" {
    for_each = nonsensitive(var.ssl_certificates)
    content {
      name                = local.certificate_names[ssl_certificate.key]
      key_vault_secret_id = ssl_certificate.value.key_vault_secret_id
      data                = ssl_certificate.value.data
      password            = ssl_certificate.value.password
    }
  }

  dynamic "identity" {
    for_each = length(var.identity_ids) == 0 ? [] : [var.identity_ids]
    content {
      type         = "UserAssigned"
      identity_ids = identity.value
    }
  }

  dynamic "http_listener" {
    for_each = var.http_listeners
    content {
      name                           = local.listener_names[http_listener.key]
      frontend_ip_configuration_name = local.frontend_ip_names[http_listener.value.frontend_type]
      frontend_port_name             = local.frontend_port_names[http_listener.value.frontend_port_key]
      protocol                       = http_listener.value.protocol
      host_name                      = http_listener.value.host_name
      host_names                     = http_listener.value.host_names
      require_sni                    = http_listener.value.require_sni
      ssl_certificate_name           = http_listener.value.ssl_certificate_key == null ? null : local.certificate_names[http_listener.value.ssl_certificate_key]
    }
  }

  dynamic "url_path_map" {
    for_each = var.url_path_maps
    content {
      name                               = local.path_map_names[url_path_map.key]
      default_backend_address_pool_name  = local.backend_pool_names[url_path_map.value.default_backend_address_pool_key]
      default_backend_http_settings_name = local.backend_setting_names[url_path_map.value.default_backend_http_settings_key]
      dynamic "path_rule" {
        for_each = url_path_map.value.path_rules
        content {
          name                       = coalesce(path_rule.value.name, path_rule.key)
          paths                      = path_rule.value.paths
          backend_address_pool_name  = local.backend_pool_names[path_rule.value.backend_address_pool_key]
          backend_http_settings_name = local.backend_setting_names[path_rule.value.backend_http_settings_key]
        }
      }
    }
  }

  dynamic "request_routing_rule" {
    for_each = var.request_routing_rules
    content {
      name                       = coalesce(request_routing_rule.value.name, request_routing_rule.key)
      priority                   = request_routing_rule.value.priority
      rule_type                  = request_routing_rule.value.rule_type
      http_listener_name         = local.listener_names[request_routing_rule.value.http_listener_key]
      backend_address_pool_name  = request_routing_rule.value.rule_type == "Basic" ? local.backend_pool_names[request_routing_rule.value.backend_address_pool_key] : null
      backend_http_settings_name = request_routing_rule.value.rule_type == "Basic" ? local.backend_setting_names[request_routing_rule.value.backend_http_settings_key] : null
      url_path_map_name          = request_routing_rule.value.rule_type == "PathBasedRouting" ? local.path_map_names[request_routing_rule.value.url_path_map_key] : null
    }
  }

  dynamic "waf_configuration" {
    for_each = var.inline_waf_configuration == null ? [] : [var.inline_waf_configuration]
    content {
      enabled                  = waf_configuration.value.enabled
      firewall_mode            = waf_configuration.value.firewall_mode
      rule_set_type            = waf_configuration.value.rule_set_type
      rule_set_version         = waf_configuration.value.rule_set_version
      file_upload_limit_mb     = waf_configuration.value.file_upload_limit_mb
      request_body_check       = waf_configuration.value.request_body_check
      max_request_body_size_kb = waf_configuration.value.max_request_body_size_kb
    }
  }

  lifecycle {
    precondition {
      condition     = var.public_ip_id != null || var.private_frontend != null
      error_message = "At least one public or private frontend must be configured."
    }
    precondition {
      condition     = var.autoscale_configuration == null ? var.capacity != null : var.capacity == null
      error_message = "Configure exactly one of autoscale_configuration or capacity."
    }
    precondition {
      condition     = var.firewall_policy_id == null || var.inline_waf_configuration == null
      error_message = "firewall_policy_id and inline_waf_configuration are mutually exclusive."
    }
    precondition {
      condition     = (var.firewall_policy_id == null && var.inline_waf_configuration == null) || var.sku_name == "WAF_v2"
      error_message = "WAF policy attachment and inline WAF configuration require sku_name = WAF_v2."
    }
    precondition {
      condition     = alltrue([for setting in values(var.backend_http_settings) : contains(keys(var.probes), setting.probe_key)])
      error_message = "Every backend_http_settings probe_key must reference an entry in probes."
    }
    precondition {
      condition     = alltrue([for listener in values(var.http_listeners) : contains(keys(var.frontend_ports), listener.frontend_port_key)])
      error_message = "Every listener frontend_port_key must reference frontend_ports."
    }
    precondition {
      condition     = alltrue([for listener in values(var.http_listeners) : listener.frontend_type != "public" || var.public_ip_id != null]) && alltrue([for listener in values(var.http_listeners) : listener.frontend_type != "private" || var.private_frontend != null])
      error_message = "Every listener must reference a configured public or private frontend."
    }
    precondition {
      condition     = alltrue([for cert in values(nonsensitive(var.ssl_certificates)) : (cert.key_vault_secret_id != null) != (cert.data != null)])
      error_message = "Each SSL certificate must set exactly one of key_vault_secret_id or data."
    }
    precondition {
      condition     = alltrue([for cert in values(nonsensitive(var.ssl_certificates)) : cert.key_vault_secret_id == null || length(var.identity_ids) > 0])
      error_message = "Key Vault-referenced SSL certificates require at least one user-assigned identity ID."
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each = var.diagnostic_settings

  name                           = coalesce(each.value.name, "${var.name}-${each.key}")
  target_resource_id             = azurerm_application_gateway.this.id
  log_analytics_workspace_id     = each.value.log_analytics_workspace_id
  log_analytics_destination_type = each.value.log_analytics_destination_type

  dynamic "enabled_log" {
    for_each = each.value.log_category_groups
    content {
      category_group = enabled_log.value
    }
  }

  dynamic "enabled_metric" {
    for_each = each.value.metric_categories
    content {
      category = enabled_metric.value
    }
  }
}
