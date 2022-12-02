# main.tf

## Register providers

The main.tf file registers the necessary Terraform providers for working with the Azure platform.

```terraform
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
```

## locals

The file also contains 1 local variable.

```terraform
locals {
  application_name = "${var.application_name}-${lower(random_string.rand-name.result)}"
}
```

The `application_name` is a concatenation of your application_name and a random string value.

## Region module

For each region you configured in your [tfvars](../tf-deploy/myvars.tfvars) file, the `region` module will be executed. You can find more info on this module in the [region.md](region.md) file.

```terraform
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
```

## shared resource group

A shared resource group gets created in the `shared_location` location. This resource group will hold the Azure Front Door service.

```terraform
resource "azurerm_resource_group" "rg" {
  name = "${var.application_name}-shared"
  location = var.shared_location
}
```

## Global LB module

For creating the Azure Front Door service with all required configuration, the `global_lb` module will be executed. You can find more info on this module in the [global_lb.md](global_lb.md) file.

```terraform
module "afd" {
  source = "./modules/global_lb"
  app_name = var.application_name
  resource_group = azurerm_resource_group.rg.name
  dns_name = var.dns_name
  backends = [for i, r in var.regions : module.region[i].appgw_ip]
  cert_id = module.region[0].cert_id
  use_self_signed_cert = var.use_self_signed_cert
}
```
