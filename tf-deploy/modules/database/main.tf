resource "random_password" "password" {
  length           = 32
  special          = true
  override_special = "_%@"
}

# resource "azurerm_mysql_flexible_server" "mysql_server" {
#   name                = var.mysql_server_name
#   resource_group_name = var.resource_group
#   location            = var.location

#   administrator_login    = var.admin_username
#   administrator_password = random_password.password.result

#   sku_name                     = "GP_Standard_D2ds_v4"
#   version                      = "5.7"
#   zone = 1
#   storage {
#     size_gb = 5120
#   }
# }

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

# This rule is to enable the 'Allow access to Azure services' checkbox
# resource "azurerm_mysql_firewall_rule" "database" {
#   name                = "allow_azure"
#   resource_group_name = var.resource_group
#   server_name         = azurerm_mysql_server.mysql_server.name
#   start_ip_address    = "0.0.0.0"
#   end_ip_address      = "0.0.0.0"
# }

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

resource "azurerm_private_dns_zone" "private_dns_zone" {
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = var.resource_group
}

resource "azurerm_private_dns_zone_virtual_network_link" "private_dns_zone_link" {
  name                  = "mysql-dns-link"
  resource_group_name   = var.resource_group
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone.name
  virtual_network_id    = var.virtual_network_id
}

resource "azurerm_private_dns_a_record" "a_record" {
  name                = "*"
  zone_name           = azurerm_private_dns_zone.private_dns_zone.name
  resource_group_name = var.resource_group
  ttl                 = 300
  records             = [azurerm_private_endpoint.mysql_pe.private_service_connection[0].private_ip_address]
}