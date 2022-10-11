output "appgw_ip" {
  value = azurerm_public_ip.appgw-pip.ip_address
}