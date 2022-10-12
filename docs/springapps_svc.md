# Spring Apps module

## Azure Spring Apps

The Spring Apps module creates your Azure Spring Apps instance inside of the virtual network. It also configures the config server backend for your spring apps instance.

```terraform
resource "azurerm_spring_cloud_service" "asa" {
  resource_group_name = var.resource_group
  name = var.asa_name
  network {
    app_subnet_id = var.app_subnet_id
    cidr_ranges = var.cidr_ranges
    service_runtime_subnet_id = var.svc_subnet_id
  }
  sku_name = "S0"
  location = var.location

  config_server_git_setting {
    uri          = var.git_repo_uri
    label        = var.git_repo_branch
    http_basic_auth {
      username = var.git_repo_username
      password = var.git_repo_password
    }
  }
}
```

## Certificate configuration

This module also adds your certificate from Key Vault to the spring apps service. This is needed for the custom domain configuration.

```terraform
resource "azurerm_spring_cloud_certificate" "asa_cert" {
  name                     = var.cert_name
  resource_group_name      = var.resource_group
  service_name             = azurerm_spring_cloud_service.asa.name
  key_vault_certificate_id = var.cert_id
}
```

## DNS configuration

For proper DNS configuration within your virtual network, a DNS zone gets created.

```terraform
resource "azurerm_private_dns_zone" "private_dns_zone" {
  name                = "private.azuremicroservices.io"
  resource_group_name = var.resource_group
}
```

This DNS zone needs to be linked to the virtual network.

```terraform
resource "azurerm_private_dns_zone_virtual_network_link" "private_dns_zone_link_asc" {
  name                  = "asc-dns-link"
  resource_group_name   = var.resource_group
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone.name
  virtual_network_id    = var.virtual_network_id
}
```

And an a-record gets created in the DNS zone for the private load balancer used by Spring Apps. This load balancer IP address is the entry point to the applications running inside the Azure Spring Apps service.

```terraform
data "azurerm_lb" "asc_internal_lb" {
  resource_group_name = "ap-svc-rt_${azurerm_spring_cloud_service.asa.name}_${azurerm_spring_cloud_service.asa.location}"
  name                = "kubernetes-internal"
  depends_on = [
    azurerm_spring_cloud_service.asa
  ]
}

resource "azurerm_private_dns_a_record" "internal_lb_record" {
  name                = "*"
  zone_name           = azurerm_private_dns_zone.private_dns_zone.name
  resource_group_name = var.resource_group
  ttl                 = 300
  records             = [data.azurerm_lb.asc_internal_lb.private_ip_address]
}
```
