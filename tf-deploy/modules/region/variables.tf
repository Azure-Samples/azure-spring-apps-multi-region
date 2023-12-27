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

variable "enterprise" {
  type = object({
    enabled = bool
    service_registry_enabled = bool
    build_agent_pool_size = string
  })
  description = "When true deploys enterprise SKU in all regions"
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
    name         = string
    uri          = string
    label        = optional(string)
    http_basic_auth = optional(object({
      username = string
    }))
    patterns     = list(string) 
  })
  description = "the regions you want the Azure Spring Apps backends to be deployed to."
}

variable "git_repo_password" {
  type = string
  sensitive = true
  default = ""
}

variable "apps" {
  type = list(object({
    app_name = string
    needs_identity = bool
    is_public = bool
    needs_custom_domain = bool
  }))
}

variable "environment_variables" {
  type = map(string)
}

variable "afd_fdid" {
  type = string
}