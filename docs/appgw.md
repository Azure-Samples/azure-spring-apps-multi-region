# Application Gateway module

## Public IP

An Application Gateway needs a public IP address. This is created first.

```terraform
resource "azurerm_public_ip" "appgw-pip" {
  name                = "app-gw-openlab-public-ip"
  resource_group_name = var.resource_group
  location            = var.location
  allocation_method   = "Static"
  sku = "Standard"
  domain_name_label = var.dns_label
}
```

## Application Gateway creation

For proper naming of all the components needed by the Application Gateway, a couple of locals get created.

```terraform
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
```

Depending on the usage of a certificate issued by a certificate authority or the usage of a self signed certificate, the application gateway will be created slightly differently. The difference is mainly in the `trusted_root_certificate_names` of the `backend_http_settings`. With a self signed certificate this root certificate name needs to be set, otherwise not.

The Application Gateway gets created with the below settings (omitting some of the config for clarity):

- `sku`: We use the `WAF_v2` sku to be able to WAF enable the Application Gateway. Since we are also using Azure Front Door, the WAF could also be enabled there.
- `frontend_port`: Both 80 and 443 get configured
- `backend_address_pool`: This will be the FQDN name of the Spring Apps service. This is the DNS name as it is configured in the private DNS zone on the network.
- `backend_http_settings`: Defines how the backend will be configured. The important setting here is the `pick_host_name_from_backend_address` which needs to be set to `false` to properly preserve the host name in the request.
- `http_listener`: 2 listeners get created on the frontend of the Application Gateway, one for Http, and one for Https.
- `request_routing_rule`: each listener has its own request routing rule, one for http and one for https.
- `ssl_certificate`: The root certificate for Application Gateway, which is stored in Key Vault.
- `identity`: The Application Gateway identity that will be used to connect to Key Vault for fetching the certificate.

```terraform
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
```

## WAF policy configuration

The Application Gateway WAF policy uses the `OWASP 3.1` default rule set.

Additionally there is a custom rule that checks the `X-Azure-FDID` request header. This is to make sure that only calls coming from your specific Azure Front Door instance make it to your backend. All other calls will be blocked. This rule works in combination with a network security group on the subnet of the Application Gateway.

```terraform
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
```
