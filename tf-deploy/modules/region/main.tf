locals {
  app_name = "${var.application_name}-${var.location-short}"
}

resource "azurerm_resource_group" "rg" {
  name = local.app_name
  location = var.location
}

module "vnet" {
  source = "../network"
  resource_group = azurerm_resource_group.rg.name
  vnet_name = "${local.app_name}-vnet"
  location = var.location
}

module "monitoring" {
  source = "../monitoring"
  asa_name = local.app_name
  resource_group = azurerm_resource_group.rg.name
  location = var.location
  asa_service_id = var.enterprise.enabled ? module.springapps_enterprise_svc[0].service_id : module.springapps_svc[0].service_id
}

module "springapps_svc" {
  source = "../springapps"
  count = var.enterprise.enabled ? 0 : 1
  resource_group = azurerm_resource_group.rg.name
  asa_name = local.app_name
  location = var.location
  app_subnet_id = module.vnet.app_subnet_id
  svc_subnet_id = module.vnet.svc_subnet_id
  appinsights = module.monitoring.connection_string
  config_server_git_setting = var.config_server_git_setting
  git_repo_password = var.git_repo_password
  virtual_network_id = module.vnet.vnet_id
  cert_id = module.keyvault.cert_id
  cert_name = var.cert_name
}

module "springapps_enterprise_svc" {
  source = "../springapps-enterprise"
  count = var.enterprise.enabled ? 1 : 0
  resource_group = azurerm_resource_group.rg.name
  asa_name = local.app_name
  location = var.location
  app_subnet_id = module.vnet.app_subnet_id
  svc_subnet_id = module.vnet.svc_subnet_id
  appinsights = module.monitoring.connection_string
  config_server_git_setting = var.config_server_git_setting
  git_repo_password = var.git_repo_password
  virtual_network_id = module.vnet.vnet_id
  cert_id = module.keyvault.cert_id
  cert_name = var.cert_name
  service_registry_enabled = var.enterprise.service_registry_enabled
  build_agent_pool_size = var.enterprise.build_agent_pool_size
}

module "database" {
  source = "../database"
  mysql_server_name = "${local.app_name}-mysql"
  resource_group = azurerm_resource_group.rg.name
  location = var.location
  admin_username = "myadmin"
  database_name = "db"
  pe_subnet_id = module.vnet.pe_subnet_id
  virtual_network_id = module.vnet.vnet_id
}

module "keyvault" {
  source = "../keyvault"
  key_vault_name = "${local.app_name}-kv"
  resource_group = azurerm_resource_group.rg.name
  location = var.location
  cert_name = var.cert_name
  database_username = module.database.database_username
  database_password = module.database.database_password
  dns_names = [var.dns_name,"*.${var.dns_name}"]
  subject = var.dns_name
  pe_subnet_id = module.vnet.pe_subnet_id
  virtual_network_id = module.vnet.vnet_id
  use_self_signed_cert = var.use_self_signed_cert
  cert_path = var.cert_path
  cert_password = var.cert_password
}

module "apps" {
  source = "../springappsapp"
  count = var.enterprise.enabled ? 0 : length(var.apps)
  needs_identity = var.apps[count.index].needs_identity
  app_name = var.apps[count.index].app_name
  resource_group = azurerm_resource_group.rg.name
  spring_cloud_service_name = local.app_name
  is_public = var.apps[count.index].is_public
  environment_variables = var.environment_variables
  vault_id = module.keyvault.kv_id
  needs_custom_domain = var.apps[count.index].needs_custom_domain
  dns_name = var.dns_name
  cert_name = var.cert_name
  thumbprint = module.springapps_svc[0].thumbprint
  depends_on = [
    module.springapps_svc
  ]
}

module "apps-enterprise" {
  source = "../springappsapp"
  count = var.enterprise.enabled ? length(var.apps) : 0
  needs_identity = var.apps[count.index].needs_identity
  app_name = var.apps[count.index].app_name
  resource_group = azurerm_resource_group.rg.name
  spring_cloud_service_name = local.app_name
  is_public = var.apps[count.index].is_public
  environment_variables = var.environment_variables
  vault_id = module.keyvault.kv_id
  needs_custom_domain = var.apps[count.index].needs_custom_domain
  dns_name = var.dns_name
  cert_name = var.cert_name
  thumbprint = module.springapps_enterprise_svc[0].thumbprint
  depends_on = [
    module.springapps_enterprise_svc
  ]
}

module "appgw" {
  source = "../appgw"
  resource_group = azurerm_resource_group.rg.name
  location = var.location
  dns_label = split(".", var.dns_name)[1] #"${var.dns_prefix}-${var.dns_postfix}"
  dns_name = var.dns_name
  app_name = local.app_name
  appgw_subnet_id = module.vnet.appgw_subnet_id
  key_vault_secret_id = module.keyvault.cert_id
  use_self_signed_cert = var.use_self_signed_cert
  appgw_identity_id = module.keyvault.appgw_identity_id
  backend_fqdn = "api-gateway.private.azuremicroservices.io"
  afd_fdid = var.afd_fdid
  depends_on = [
    module.keyvault
  ]
}

