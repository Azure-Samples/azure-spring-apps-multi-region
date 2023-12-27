output "thumbprint" {
  value = azurerm_spring_cloud_certificate.asa_cert.thumbprint
}

output "service_id" {
  value = azurerm_spring_cloud_service.asa.id
}