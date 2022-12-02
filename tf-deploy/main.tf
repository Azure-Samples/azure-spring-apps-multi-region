# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.25.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.15.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

locals {
  application_name = "${var.application_name}-${lower(random_id.randomval.hex)}"
}

resource "random_id" "randomval" {
  byte_length = 6
}

module "region" {
  source = "./modules/region"
  for_each = {for i, r in var.regions:  i => r}
  application_name = local.application_name
  location = each.value.location
  location-short = each.value.location-short

  dns_name = var.dns_name
  cert_name = var.cert_name
  use_self_signed_cert = var.use_self_signed_cert
  cert_path = var.cert_path
  cert_password = var.cert_password

  config_server_git_setting = each.value.config_server_git_setting
  git_repo_password = var.git_repo_passwords == null ? "" : var.git_repo_passwords[index(var.regions, each.value)]
  apps = var.apps
  environment_variables = var.environment_variables
  afd_fdid = module.afd.afd_fdid
}

resource "azurerm_resource_group" "rg" {
  name = "${local.application_name}-shared"
  location = var.shared_location
}

module "afd" {
  source = "./modules/global_lb"
  app_name = local.application_name
  resource_group = azurerm_resource_group.rg.name
  dns_name = var.dns_name
  backends = [for i, r in var.regions : module.region[i].appgw_ip]
  cert_id = module.region[0].cert_id
  use_self_signed_cert = var.use_self_signed_cert
}
