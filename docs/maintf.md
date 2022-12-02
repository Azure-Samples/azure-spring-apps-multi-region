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
    azapi = {
      source  = "Azure/azapi"
      version = "0.4.0"
    }
  }
}

provider "azapi" {

}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}
```

## locals

The file also contains 2 local variables.

```terraform
locals {
  apps = [
    {
      app_name = "api-gateway",
      needs_identity = false
      is_public = true
      needs_custom_domain = true
    },
    {
      app_name = "admin-service",
      needs_identity = false
      is_public = true
      needs_custom_domain = false
    },
    {
      app_name = "customers-service",
      needs_identity = true
      is_public = false
      needs_custom_domain = false
    },
    {
      app_name = "visits-service",
      needs_identity = true
      is_public = false
      needs_custom_domain = false
    },
    {
      app_name = "vets-service",
      needs_identity = true
      is_public = false
      needs_custom_domain = false
    }
  ]
  microservices_env = {
    "SPRING_PROFILES_ACTIVE"     = "mysql"
  }
}
```

The apps local defines different apps that will be deployed to the Spring Apps service in each region you deploy to. Each app has:

- `app_name`: name of the application in Spring Apps
- `needs_identity`: defines whether a managed identity for the app will be created. This can be used when connecting to other services like Key Vault.
- `is_public`: defines whether this app is a spring cloud api-gateway. Currently the template only supports 1 app as a gateway.
- `needs_custom_domain`: defines whether this is the app where your custom domain needs to be configured. The endpoint to this app will be used as a backend for the Application Gateway service.

In the sample local variable, the api-gateway is configured with `is_public` and `needs_custom_domain` set to `true`. This means the applications will be exposed through Application Gateway through the api-gateway app in Spring Apps.

The `admin-service` however is only configured with `is_public` set to true. This app will only be accessible within the virtual network and not through the Application Gateway.

The `microservices_env` local value is an extra environment value that gets set on each spring app. Basically this prepares this sample for deploying the [spring petclinic microservices](https://github.com/spring-petclinic/spring-petclinic-microservices) application to this Spring Apps instance.

## Region module

For each region you configured in your [tfvars](../tf-deploy/myvars.tfvars) file, the `region` module will be executed. You can find more info on this module in the [region.md](region.md) file.

```terraform
module "region" {
  source = "./modules/region"
  for_each = {for i, r in var.regions:  i => r}
  application_name = var.application_name
  location = each.value.location
  location-short = each.value.location-short

  dns_name = var.dns_name
  cert_name = var.cert_name
  use_self_signed_cert = var.use_self_signed_cert
  cert_path = var.cert_path
  cert_password = var.cert_password

  git_repo_uri = each.value.git_repo_uri
  git_repo_branch = each.value.git_repo_branch
  git_repo_username = each.value.git_repo_username
  git_repo_password = var.git_repo_passwords[index(var.regions, each.value)]
  apps = local.apps
  microservices_env = local.microservices_env
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
