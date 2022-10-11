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

# Gets the Azure Spring Apps internal load balancer IP address once it is deployed
data "azurerm_lb" "asc_internal_lb" {
  resource_group_name = "ap-svc-rt_${azurerm_spring_cloud_service.asa.name}_${azurerm_spring_cloud_service.asa.location}"
  name                = "kubernetes-internal"
  depends_on = [
    azurerm_spring_cloud_service.asa
  ]
}

# Create DNS zone
resource "azurerm_private_dns_zone" "private_dns_zone" {
  name                = "private.azuremicroservices.io"
  resource_group_name = var.resource_group
}

# Link DNS to Azure Spring Apps virtual network
resource "azurerm_private_dns_zone_virtual_network_link" "private_dns_zone_link_asc" {
  name                  = "asc-dns-link"
  resource_group_name   = var.resource_group
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone.name
  virtual_network_id    = var.virtual_network_id
}

# Creates an A record that points to Azure Spring Apps internal balancer IP
resource "azurerm_private_dns_a_record" "internal_lb_record" {
  name                = "*"
  zone_name           = azurerm_private_dns_zone.private_dns_zone.name
  resource_group_name = var.resource_group
  ttl                 = 300
  records             = [data.azurerm_lb.asc_internal_lb.private_ip_address]
}

resource "azurerm_spring_cloud_certificate" "asa_cert" {
  name                     = var.cert_name
  resource_group_name      = var.resource_group
  service_name             = azurerm_spring_cloud_service.asa.name
  key_vault_certificate_id = var.cert_id
}