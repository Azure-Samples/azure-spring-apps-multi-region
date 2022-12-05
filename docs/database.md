# Database module

## Database creation

The database is created with a random password that gets created. This password gets outputted and stored in the Key Vault.

```terraform
resource "random_password" "password" {
  length           = 32
  special          = true
  override_special = "_%@"
}

resource "azurerm_mysql_server" "mysql_server" {
  name                = var.mysql_server_name
  location            = var.location
  resource_group_name = var.resource_group

  administrator_login          = var.admin_username
  administrator_login_password = random_password.password.result

  sku_name   = "GP_Gen5_8"
  storage_mb = 5120
  version    = "5.7"

  ssl_enforcement_enabled           = true

  public_network_access_enabled = false
}

resource "azurerm_mysql_database" "database" {
  name                = var.database_name
  resource_group_name = var.resource_group
  server_name         = azurerm_mysql_server.mysql_server.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}
```

## Network configuration

A private endpoint within the network also gets created for the database.

```terraform
resource "azurerm_private_endpoint" "mysql_pe" {
  name                = "${var.database_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group
  subnet_id           = var.pe_subnet_id

  private_service_connection {
    name                           = "${var.database_name}-privateserviceconnection"
    private_connection_resource_id = azurerm_mysql_server.mysql_server.id
    subresource_names              = [ "mysqlServer" ]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.private_dns_zone.id]
  }
}
```

For proper DNS configuration within your virtual network, a DNS zone gets created.

```terraform
resource "azurerm_private_dns_zone" "private_dns_zone" {
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = var.resource_group
}
```

This DNS zone needs to be linked to the virtual network.

```terraform
resource "azurerm_private_dns_zone_virtual_network_link" "private_dns_zone_link" {
  name                  = "mysql-dns-link"
  resource_group_name   = var.resource_group
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone.name
  virtual_network_id    = var.virtual_network_id
}
```

And an a-record gets created in the DNS zone for the private IP address of the private endpoint.

```terraform
resource "azurerm_private_dns_a_record" "a_record" {
  name                = "*"
  zone_name           = azurerm_private_dns_zone.private_dns_zone.name
  resource_group_name = var.resource_group
  ttl                 = 300
  records             = [azurerm_private_endpoint.mysql_pe.private_service_connection[0].private_ip_address]
}
```
