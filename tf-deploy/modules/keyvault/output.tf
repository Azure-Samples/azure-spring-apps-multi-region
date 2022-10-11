# output "cert_id" {
#   value = var.use_self_signed_cert ? azurerm_key_vault_certificate.self_signed_cert[0].secret_id : data.azurerm_key_vault_certificate.uploaded_cert[0].secret_id
# }

output "cert_id" {
  value = var.use_self_signed_cert ? azurerm_key_vault_certificate.self_signed_cert[0].secret_id : azurerm_key_vault_certificate.uploaded_cert[0].secret_id
}

output "kv_id" {
    value = azurerm_key_vault.kv.id
}

output "appgw_identity_id" {
    value = azurerm_user_assigned_identity.appgw_id.id
}
