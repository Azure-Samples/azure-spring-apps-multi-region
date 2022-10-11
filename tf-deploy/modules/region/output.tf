output "appgw_ip" {
  value = module.appgw.appgw_ip
}

output "cert_id" {
  value = module.keyvault.cert_id
}