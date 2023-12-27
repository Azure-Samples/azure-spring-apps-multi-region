resource "azurerm_spring_cloud_service" "asa" {
  resource_group_name = var.resource_group
  name = var.asa_name
  network {
    app_subnet_id = var.app_subnet_id
    cidr_ranges = var.cidr_ranges
    service_runtime_subnet_id = var.svc_subnet_id
  }
  sku_name = "E0"
  location = var.location
  
  service_registry_enabled = var.service_registry_enabled
  build_agent_pool_size = var.build_agent_pool_size

  trace {
    connection_string = var.appinsights
    sample_rate       = 10.0
  }
}

resource "azurerm_spring_cloud_configuration_service" "asa_config_svc" {
  name                    = "default"
  spring_cloud_service_id = azurerm_spring_cloud_service.asa.id

  dynamic repository {
    for_each = var.config_server_git_setting.http_basic_auth.username == "" ? [] : [1]
    content {
      name     = var.config_server_git_setting.name
      label    = var.config_server_git_setting.label
      patterns = var.config_server_git_setting.patterns
      uri      = var.config_server_git_setting.uri

      username = var.config_server_git_setting.http_basic_auth.username
      password = var.git_repo_password    
    }
  }

  dynamic repository {
    for_each = var.config_server_git_setting.http_basic_auth.username == "" ? [1] : []
    content {
      name     = var.config_server_git_setting.name
      label    = var.config_server_git_setting.label
      patterns = var.config_server_git_setting.patterns
      uri      = var.config_server_git_setting.uri  
    }
  }
}

# Configure Tanzu Build Service for ASA
resource "azurerm_spring_cloud_builder" "asa_builder" {
  name                    = "no-bindings-builder"
  spring_cloud_service_id = azurerm_spring_cloud_service.asa.id
  build_pack_group {
    name           = "default"
    build_pack_ids = ["tanzu-buildpacks/nodejs", "tanzu-buildpacks/dotnet-core", "tanzu-buildpacks/go", "tanzu-buildpacks/python"]
  }
  stack {
    id      = "io.buildpacks.stacks.bionic"
    version = "full"
  }
}

# Configure Gateway for ASA (let's do it for now without)
# resource "azurerm_spring_cloud_gateway" "asa_gateway" {
#   name                    = "default"
#   spring_cloud_service_id = azurerm_spring_cloud_service.asa_service.id

#   application_performance_monitoring_types = "ApplicationInsights"

#   https_only = false
#   public_network_access_enabled = false

#   cors {
#     allowed_origins = ["*"]
#   }

#   instance_count                = 2
# }

# TODO
# resource "azurerm_spring_cloud_api_portal" "asa_api" {
#   name                    = "default"
#   spring_cloud_service_id = azurerm_spring_cloud_service.asa_service.id
#   gateway_ids             = [azurerm_spring_cloud_gateway.asa_gateway.id]
  # sso {
  #   client_id     = var.sso-client-id
  #   client_secret = var.sso-client-secret
  #   issuer_uri    = var.sso-issuer-uri
  #   scope         = var.sso-scope
  # }

#   public_network_access_enabled = true
# }

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
