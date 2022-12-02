variable "application_name" {
  type        = string
  description = "The name of your application"
}

variable "location" {
  type        = string
  description = "The Azure region where all resources in this example should be created in"
}

variable "location-short" {
  type        = string
  description = "The short name of the Azure region where all resources in this example should be created in. Used for creating unique resource names"
}

variable "dns_name" {
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

variable "config_server_git_setting" {
  type = object ({
    uri          = string
    label        = optional(string)
    http_basic_auth = optional(object({
      username = string
    }))
  })
  description = "the regions you want the Azure Spring Apps backends to be deployed to."
}

variable "apps" {
  type = list(object({
    app_name = string
    needs_identity = bool
    is_public = bool
    needs_custom_domain = bool
  }))
}

variable "microservices_env" {
  type = map(string)
}

variable "afd_fdid" {
  type = string
}