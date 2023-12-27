resource "azurerm_cdn_frontdoor_profile" "profile" {
  name                = "${var.app_name}-afd"
  resource_group_name = var.resource_group
  sku_name            = "Standard_AzureFrontDoor"
}

resource "azurerm_cdn_frontdoor_endpoint" "endpoint" {
  name                     = "${var.app_name}-afd-ep"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.profile.id
}

resource "azurerm_cdn_frontdoor_origin_group" "origin-group" {
  name                     = "${var.app_name}-afd-og"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.profile.id

  health_probe {
    interval_in_seconds = 240
    path                = "/"
    protocol            = "Http"
    request_type        = "HEAD"
  }

  load_balancing {
    additional_latency_in_milliseconds = 0
    successful_samples_required        = 3
  }
}

resource "azurerm_cdn_frontdoor_origin" "originss" {
  for_each = var.use_self_signed_cert ? {for i, b in var.backends:  i => b} : {}
  name                                  = "${var.app_name}-afd-o-${index(var.backends, each.value)}"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.origin-group.id

  enabled          = true
  certificate_name_check_enabled = true

  host_name          = each.value
  http_port          = 80
  https_port         = 443
  origin_host_header = var.dns_name
  priority           = 1
  weight             = 1
}

resource "azurerm_cdn_frontdoor_origin" "origin" {
  for_each = var.use_self_signed_cert ? {} : {for i, b in var.backends:  i => b} 
  name                                  = "${var.app_name}-afd-o-${index(var.backends, each.value)}"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.origin-group.id

  enabled          = true
  certificate_name_check_enabled = true

  host_name          = each.value
  http_port          = 80
  https_port         = 443
  priority           = 1
  weight             = 1
}

resource "azurerm_cdn_frontdoor_route" "route" {
  name                          = "${var.app_name}-afd-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.origin-group.id
  cdn_frontdoor_origin_ids      = [for i, b in var.backends : var.use_self_signed_cert ? azurerm_cdn_frontdoor_origin.originss[i].id : azurerm_cdn_frontdoor_origin.origin[i].id]
  enabled                       = true

  forwarding_protocol    = "HttpOnly"
  https_redirect_enabled = false
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]
}

# self-signed cert not allowed on AFD
resource "azurerm_cdn_frontdoor_secret" "secret" {
  count = var.use_self_signed_cert ? 0 : 1
  name                     = "${var.app_name}-afd-secr"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.profile.id

  secret {
    customer_certificate {
      key_vault_certificate_id = var.cert_id
    }
  }
}

# verify custom domain with txt record in DNS 
resource "azurerm_cdn_frontdoor_custom_domain" "custom_domain" {
  count = var.use_self_signed_cert ? 0 : 1
  name                     = "${var.app_name}-custom-domain"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.profile.id
  host_name                = var.dns_name

#  associate_with_cdn_frontdoor_route_id = azurerm_cdn_frontdoor_route.route.id

  tls {
    certificate_type    = "CustomerCertificate"
    minimum_tls_version = "TLS12"
    cdn_frontdoor_secret_id = azurerm_cdn_frontdoor_secret.secret[0].id
  }
}
