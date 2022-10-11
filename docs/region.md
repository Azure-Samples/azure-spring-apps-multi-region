# region module

## locals

The region module uses 1 local value to create the name for all the subresources.

```terraform
locals {
  app_name = "${var.application_name}-${var.location-short}"
}
```

If your `application_name` is `my_app` and you deploy to the `weu` region, this will result in the `myapp-weu` name for all your resources.

## Resource group

For this region a resource group will get created. This resource group will contain all the next resources.

```terraform
resource "azurerm_resource_group" "rg" {
  name = local.app_name
  location = var.location
}
```

## Modules

Next this template will use the following modules to create the resources in this resource group:

- `vnet`: Creates the virtual network and all needed subnets. More info in the [vnet.md](vnet.md) file.
- `springapps_svc`: Create the Spring Apps service inside the virtual network. This module will also configure the certificate in the Spring Apps service for the custom domain. More info in the [vspringapps_svcnet.md](springapps_svc.md) file.
- `database`: Creates the MySQL Database server and database. This will also create a private endpoint for this database inside the virtual network. More info in the [database.md](database.md) file.
- `keyvault`: Creates the Key Vault service and configure proper access rules for keys secrets and certificates. This will also store the database username and password as well as the certificate for your custom domain. The Key Vault will also be configured with a Private Endpoint in the virtual network. More info in the [keyvault.md](keyvault.md) file.
- `apps`: Creates the apps in the Spring Apps service. More info in the [apps.md](apps.md) file.
- `appgw`: Creates the Application Gateway in the virtual network. This module will also link the Key Vault certificate to this Application Gateway and configure the Spring Apps service as a backend. More info in the [appgw.md](appgw.md) file.
