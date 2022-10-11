#gittedomain-java-openlab.com
resource "azurerm_public_ip" "appgw-pip" {
  name                = "app-gw-openlab-public-ip"
  resource_group_name = var.resource_group
  location            = var.location
  allocation_method   = "Static"
  sku = "Standard"
  domain_name_label = var.dns_label
}

locals {
  backend_address_pool_name      = "${var.app_name}-beap"
  frontend_port_name             = "${var.app_name}-feport"
  frontend_ip_configuration_name = "${var.app_name}-feip"
  http_setting_name              = "${var.app_name}-be-htst"
  listener_name                  = "${var.app_name}-lstn"
  request_routing_rule_name      = "${var.app_name}-rr"
  redirect_configuration_name    = "${var.app_name}-rdrcfg"
  rootcert_name                  = "${var.app_name}-rootcert"
  cert_name                      = "${var.app_name}-cert"
  probe_name                      = "${var.app_name}-probe"
}

resource "azurerm_application_gateway" "appgwss" {
  count = var.use_self_signed_cert ? 1 : 0
  name                = "${var.app_name}-gw"
  resource_group_name = var.resource_group
  location            = var.location

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = var.appgw_subnet_id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 443
  }

  frontend_port {
    name = "${local.frontend_port_name}-http"
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.appgw-pip.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
    fqdns = [ var.backend_fqdn ]
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    port                  = 443
    protocol              = "Https"
    request_timeout       = 60
    pick_host_name_from_backend_address = false
    trusted_root_certificate_names = var.use_self_signed_cert ? [ local.rootcert_name ] : []
    probe_name = local.probe_name
  }

  probe {
    host = var.dns_name
    interval = 30
    name = local.probe_name
    protocol = "Https"
    path = "/"
    timeout = 30
    unhealthy_threshold = 3
  }

  http_listener {
    name                           = "${local.listener_name}-https"
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Https"
    ssl_certificate_name = local.cert_name
    firewall_policy_id = azurerm_web_application_firewall_policy.waf_policy.id
  }

  http_listener {
    name                           = "${local.listener_name}-http"
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = "${local.frontend_port_name}-http"
    protocol                       = "Http"
    firewall_policy_id = azurerm_web_application_firewall_policy.waf_policy.id
  }

  request_routing_rule {
    name                       = "${local.request_routing_rule_name}-https"
    rule_type                  = "Basic"
    http_listener_name         = "${local.listener_name}-https"
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name  
    priority = 1 
  }

  request_routing_rule {
    name                       = "${local.request_routing_rule_name}-http"
    rule_type                  = "Basic"
    http_listener_name         = "${local.listener_name}-http"
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name  
    priority = 2 
  }

  trusted_root_certificate {
    name = var.use_self_signed_cert ? local.rootcert_name : ""
    key_vault_secret_id = var.use_self_signed_cert ? var.key_vault_secret_id : ""
  }

  ssl_certificate {
    name = local.cert_name
    key_vault_secret_id = var.key_vault_secret_id
  }

  identity {
    identity_ids = [ var.appgw_identity_id ]
    type = "UserAssigned"
  }
}

resource "azurerm_application_gateway" "appgw" {
  count = var.use_self_signed_cert ? 0 : 1
  name                = "${var.app_name}-gw"
  resource_group_name = var.resource_group
  location            = var.location

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = var.appgw_subnet_id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 443
  }

  frontend_port {
    name = "${local.frontend_port_name}-http"
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.appgw-pip.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
    fqdns = [ var.backend_fqdn ]
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    port                  = 443
    protocol              = "Https"
    request_timeout       = 60
    pick_host_name_from_backend_address = false
    trusted_root_certificate_names = var.use_self_signed_cert ? [ local.rootcert_name ] : []
    probe_name = local.probe_name
  }

  probe {
    host = var.dns_name
    interval = 30
    name = local.probe_name
    protocol = "Https"
    path = "/"
    timeout = 30
    unhealthy_threshold = 3
  }

  http_listener {
    name                           = "${local.listener_name}-https"
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Https"
    ssl_certificate_name = local.cert_name
    firewall_policy_id = azurerm_web_application_firewall_policy.waf_policy.id
  }

  http_listener {
    name                           = "${local.listener_name}-http"
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = "${local.frontend_port_name}-http"
    protocol                       = "Http"
    firewall_policy_id = azurerm_web_application_firewall_policy.waf_policy.id
  }

  request_routing_rule {
    name                       = "${local.request_routing_rule_name}-https"
    rule_type                  = "Basic"
    http_listener_name         = "${local.listener_name}-https"
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name  
    priority = 1 
  }

  request_routing_rule {
    name                       = "${local.request_routing_rule_name}-http"
    rule_type                  = "Basic"
    http_listener_name         = "${local.listener_name}-http"
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name  
    priority = 2 
  }

  ssl_certificate {
    name = local.cert_name
    key_vault_secret_id = var.key_vault_secret_id
  }

  identity {
    identity_ids = [ var.appgw_identity_id ]
    type = "UserAssigned"
  }
}

resource "azurerm_web_application_firewall_policy" "waf_policy" {
  name                = "openlab-wafpolicy"
  resource_group_name = var.resource_group
  location            = var.location

  policy_settings {
    enabled                     = true
    mode                        = "Detection"
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.1"
    }
  }

  custom_rules {
    name      = "onlyMyAFD"
    priority  = 2
    rule_type = "MatchRule"

    match_conditions {
      match_variables {
        variable_name = "RequestHeaders"
        selector      = "X-Azure-FDID"
      }

      operator           = "Equal"
      negation_condition = true
      match_values       = [var.afd_fdid]
    }

    action = "Block"
  }
}