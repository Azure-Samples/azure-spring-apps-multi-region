variable "needs_identity" {
  type = bool
  default = false
}

variable "app_name" {
  type = string
}

variable "resource_group" {
  type = string
}

variable "spring_cloud_service_name" {
  type = string
}

variable "is_public" {
  type = string
}

variable "environment_variables" {
  type = map(string)
}

variable "vault_id" {
  type = string
}

variable "needs_custom_domain" {
  type = bool
  default = false
}

variable "dns_name" {
  type = string
}

variable "cert_name" {
  type = string
}

variable "thumbprint" {
  type = string
}