output "app_subnet_id" {
  value       = azurerm_subnet.apps_subnet.id
}

output "svc_subnet_id" {
  value = azurerm_subnet.svc_runtime_subnet.id
}

output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "appgw_subnet_id" {
  value = azurerm_subnet.appgw_subnet.id
}

output "pe_subnet_id" {
  value = azurerm_subnet.pe_subnet.id
}