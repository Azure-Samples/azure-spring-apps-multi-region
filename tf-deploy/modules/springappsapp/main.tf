resource "azurerm_spring_cloud_app" "app" {
  name                = var.app_name
  resource_group_name = var.resource_group
  service_name        = var.spring_cloud_service_name
  is_public = var.is_public

  dynamic identity {
    for_each = var.needs_identity == true ? [1] : []
    content {
        type = "SystemAssigned"
    }
  }
}

resource "azurerm_spring_cloud_java_deployment" "deployment" {
  name                = "default"
  spring_cloud_app_id = azurerm_spring_cloud_app.app.id
  instance_count      = 1
  runtime_version     = "Java_8"

  quota {
    cpu    = "1"
    memory = "1Gi"
  }

  environment_variables = var.environment_variables
}

resource "azurerm_spring_cloud_active_deployment" "active-deployment" {
  spring_cloud_app_id = azurerm_spring_cloud_app.app.id
  deployment_name     = azurerm_spring_cloud_java_deployment.deployment.name
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault_access_policy" "access" {
  count = var.needs_identity ? 1 : 0
  key_vault_id = var.vault_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_spring_cloud_app.app.identity[0].principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
}

resource "azurerm_spring_cloud_custom_domain" "custom_domain" {
  count = var.needs_custom_domain ? 1 : 0
  name                = var.dns_name
  spring_cloud_app_id = azurerm_spring_cloud_app.app.id
  certificate_name = var.cert_name
  thumbprint = var.thumbprint
}