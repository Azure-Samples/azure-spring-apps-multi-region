# Azure Front Door module

## Front Door creation

The Azure Front Door needs for it's creation a `azurerm_cdn_frontdoor_profile`, which represents the instance, and a `azurerm_cdn_frontdoor_endpoint` where all calls come into.

```terraform
resource "azurerm_cdn_frontdoor_profile" "profile" {
  name                = "${var.app_name}-afd"
  resource_group_name = var.resource_group
  sku_name            = "Standard_AzureFrontDoor"
}

resource "azurerm_cdn_frontdoor_endpoint" "endpoint" {
  name                     = "${var.app_name}-afd-ep"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.profile.id
}
```

Front Door then uses an origin group for it's destinations. This is where the health probe gets configured and how you want to load balance.

```terraform
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
```

An origin group holds the different origins which get configured with the different backends Azure Front Door connects to. In this case these origins get configured with each of the Application Gateway front end IP addresses in each of the regions you deploy to.

When using a self-signed certificate, `originss` is used for the configuration. In this case the `origin_host_header` value is set, meaning you override the host name.

> [!NOTE]
> Overwriting the host name should only be done in non-production scenario's. It will break certain scenario's as described [here](https://learn.microsoft.com/en-us/azure/architecture/best-practices/host-name-preservation)

When using a certificate from a certificate authority, this host name override will not be done and the host name is preserved across the call to the backend. This is the `origin` resource.

```terraform
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
```

A `azurerm_cdn_frontdoor_route` is created to link the endpoint, the origin and origin group together.

```terraform
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
```

## Custom domain configuration

When using a certificate from a certificate authority, this certificate is also added to Azure Front Door as a secret. You can't perform this linking with a self-signed certificate, since Azure Front Door does not allow for a self-signed certificate to be linked.

```terraform
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
```

You can now create a custom domain by using this certificate.

```terraform
resource "azurerm_cdn_frontdoor_custom_domain" "custom_domain" {
  count = var.use_self_signed_cert ? 0 : 1
  name                     = "${var.app_name}-custom-domain"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.profile.id
  host_name                = var.dns_name

  associate_with_cdn_frontdoor_route_id = azurerm_cdn_frontdoor_route.route.id

  tls {
    certificate_type    = "CustomerCertificate"
    minimum_tls_version = "TLS12"
    cdn_frontdoor_secret_id = azurerm_cdn_frontdoor_secret.secret[0].id
  }
}
```

## Extra manual step

If you check your Azure Front Door custom domain in the Azure Portal, you will notice the domain still needs to be verified. Terraform can only get you this far here. For verifying your custom domain, you can use a TXT record that you add to your DNS. Once you add this TXT record, the domain validity can be checked by Azure Front Door.

In the Azure Portal go to your Azure Front Door service > select `Custom Domain` > Select the `Pending` message in the custom domain entry. This will show a flyout with details on the TXT record you need to add in your DNS configuration for the verification.

![](../images/Screenshot%20AFD.png)

Once the domain has been verified, you can connect to your application through your custom domain name.

In case you are using a self-signed certificate this extra step is not needed. You connect to your application using the DNS name of your Azure Front Door service.
