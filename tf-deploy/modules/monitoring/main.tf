resource "azurerm_log_analytics_workspace" "asa_workspace" {
  name                = "${var.asa_name}-workspace"
  location            = var.location
  resource_group_name = var.resource_group
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "asa_app_insights" {
  name                = "${var.asa_name}-appinsights"
  location            = var.location
  resource_group_name = var.resource_group
  workspace_id        = azurerm_log_analytics_workspace.asa_workspace.id
  application_type    = "web"
}

resource "azurerm_monitor_diagnostic_setting" "asa_diagnostic" {
  name                       = "${var.asa_name}-diagnostic"
  target_resource_id         = azurerm_spring_cloud_service.asa_service.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.asa_workspace.id

  enabled_log {
    category = "ApplicationConsole"
  }
  enabled_log {
    category = "SystemLogs"
  }
  enabled_log {
    category = "IngressLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

