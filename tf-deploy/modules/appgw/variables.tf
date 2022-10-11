variable "resource_group" {
  type = string
}

variable "location" {
  type = string
}

variable "dns_label" {
  type = string
}

variable "dns_name" {
  type = string
}

variable "app_name" {
  type = string
}

variable "appgw_subnet_id" {
  type = string
}

variable "key_vault_secret_id" {
  type = string
}

variable "use_self_signed_cert" {
  type = string
}

variable "appgw_identity_id" {
  type = string
}

variable "backend_fqdn" {
  type = string
}

variable "afd_fdid" {
  type = string
}