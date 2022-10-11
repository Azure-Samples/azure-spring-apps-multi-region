variable "resource_group" {
  type = string
}

variable "app_name" {
  type = string
}

variable "dns_name" {
  type = string
}

variable "backends" {
  type = list(string)
}

variable "cert_id" {
  type = string
}

variable "use_self_signed_cert" {
  type = bool
}