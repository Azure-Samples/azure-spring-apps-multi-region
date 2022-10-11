variable "key_vault_name" {
  type = string
}

variable "resource_group" {
  type = string
}

variable "location" {
  type = string
}

variable "database_username" {
  type = string
}

variable "database_password" {
  type = string
}

variable "dns_names" {
  type = list(string)
}

variable "subject" {
  type = string
}

variable "cert_name" {
  type = string
}

variable "use_self_signed_cert" {
  type = bool
  default = true
}

variable "cert_path" {
  type = string
}

variable "cert_password" {
  type = string
  sensitive = true
}

variable "pe_subnet_id" {
  type = string
}

variable "virtual_network_id" {
  type = string
}