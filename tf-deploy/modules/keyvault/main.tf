data "azurerm_client_config" "current" {}

data "azuread_service_principal" "asa-id" {
  display_name = "Azure Spring Cloud Domain-Management"
}

data "azuread_service_principal" "afd-id" {
  display_name = "Microsoft.Azure.Frontdoor"
}

data "azuread_service_principal" "afd-cdn" {
  display_name = "Microsoft.AzureFrontDoor-Cdn"
}

resource "azurerm_user_assigned_identity" "appgw_id" {
  resource_group_name = var.resource_group
  location            = var.location

  name = "msi-appgw-openlab"
}

resource "azurerm_key_vault" "kv" {
  name                = var.key_vault_name
  resource_group_name = var.resource_group
  location            = var.location

  tenant_id                  = data.azurerm_client_config.current.tenant_id

  sku_name = "standard"

  access_policy {
    certificate_permissions = [
          "Create",
          "Delete",
          "DeleteIssuers",
          "Get",
          "GetIssuers",
          "Import",
          "List",
          "ListIssuers",
          "ManageContacts",
          "ManageIssuers",
          "Purge",
          "SetIssuers",
          "Update",
        ]
    key_permissions = [
          "Backup",
          "Create",
          "Decrypt",
          "Delete",
          "Encrypt",
          "Get",
          "Import",
          "List",
          "Purge",
          "Recover",
          "Restore",
          "Sign",
          "UnwrapKey",
          "Update",
          "Verify",
          "WrapKey",
        ]
    object_id = data.azurerm_client_config.current.object_id
    secret_permissions = [
          "Backup",
          "Delete",
          "Get",
          "List",
          "Purge",
          "Recover",
          "Restore",
          "Set",
        ]
    tenant_id = data.azurerm_client_config.current.tenant_id
  }

  access_policy {
    tenant_id               = data.azurerm_client_config.current.tenant_id
    object_id               = data.azuread_service_principal.asa-id.object_id
    secret_permissions      = ["Get", "List"]
    certificate_permissions = ["Get", "List"]
  }

  access_policy {
    tenant_id               = data.azurerm_client_config.current.tenant_id
    object_id               = data.azuread_service_principal.afd-id.object_id
    secret_permissions      = ["Get", "List"]
    certificate_permissions = ["Get", "List"]
  }

  access_policy {
    tenant_id               = data.azurerm_client_config.current.tenant_id
    object_id               = data.azuread_service_principal.afd-cdn.object_id
    secret_permissions      = ["Get", "List"]
    certificate_permissions = ["Get", "List"]
  }

  access_policy {
    tenant_id               = data.azurerm_client_config.current.tenant_id
    object_id               = azurerm_user_assigned_identity.appgw_id.principal_id
    secret_permissions      = ["Get", "List"]
    certificate_permissions = ["Get", "List"]    
  }
}



resource "azurerm_key_vault_secret" "database_username" {
  name         = "SPRING-DATASOURCE-USERNAME"
  value        = var.database_username
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [ azurerm_key_vault.kv ]
}

resource "azurerm_key_vault_secret" "database_password" {
  name         = "SPRING-DATASOURCE-PASSWORD"
  value        = var.database_password
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [ azurerm_key_vault.kv ]
}

resource "azurerm_key_vault_certificate" "uploaded_cert" {
  count = var.use_self_signed_cert ? 0 : 1
  name         = var.cert_name
  key_vault_id = azurerm_key_vault.kv.id

  certificate {
    contents = filebase64(var.cert_path)
    password = var.cert_password
  }
}

resource "azurerm_key_vault_certificate" "self_signed_cert" {
  count = var.use_self_signed_cert ? 1 : 0
  name         = var.cert_name
  key_vault_id = azurerm_key_vault.kv.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      # Server Authentication = 1.3.6.1.5.5.7.3.1
      # Client Authentication = 1.3.6.1.5.5.7.3.2
      extended_key_usage = ["1.3.6.1.5.5.7.3.1"]

      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]

      subject_alternative_names {
        dns_names = var.dns_names
      }

      subject            = "C=US, ST=WA, L=Redmond, O=Contoso, OU=Contoso HR, CN=${var.subject}"
      validity_in_months = 12
    }
  }
  depends_on = [
    azurerm_key_vault.kv
  ]
}

resource "azurerm_private_endpoint" "kv_pe" {
  name                = "${var.key_vault_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group
  subnet_id           = var.pe_subnet_id

  private_service_connection {
    name                           = "${var.key_vault_name}-privateserviceconnection"
    private_connection_resource_id = azurerm_key_vault.kv.id
    subresource_names              = [ "vault" ]
    is_manual_connection           = false
  }
 
  private_dns_zone_group {
    name                 = "private-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.private_dns_zone.id]
  }
}

resource "azurerm_private_dns_zone" "private_dns_zone" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group
}

resource "azurerm_private_dns_zone_virtual_network_link" "private_dns_zone_link" {
  name                  = "kv-dns-link"
  resource_group_name   = var.resource_group
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone.name
  virtual_network_id    = var.virtual_network_id
}

resource "azurerm_private_dns_a_record" "a_record" {
  name                = "*"
  zone_name           = azurerm_private_dns_zone.private_dns_zone.name
  resource_group_name = var.resource_group
  ttl                 = 300
  records             = [azurerm_private_endpoint.kv_pe.private_service_connection[0].private_ip_address]
}