output "afd_fdid" {
  value = azurerm_cdn_frontdoor_profile.profile.resource_guid
}

output "host_name" {
  value = azurerm_cdn_frontdoor_endpoint.endpoint.host_name
}