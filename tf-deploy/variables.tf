variable "application_name" {
  type        = string
  description = "The name of your application"
  default     = "asa-mr"
}

variable "regions" {
  type = list(object({
    location = string
    location-short = string
    config_server_git_setting = object({
      name         = string
      uri          = string
      label        = optional(string)
      patterns     = list(string) 
      http_basic_auth = optional(object ({
        username = string
      }), {username = ""})
    })
  }))
  description = "the regions you want the Azure Spring Apps backends to be deployed to."
}

variable "enterprise" {
  type = object({
    enabled = bool
    service_registry_enabled = bool
    build_agent_pool_size = string
  })
  description = "When true deploys enterprise SKU in all regions"
  default = {
    enabled = false
    service_registry_enabled = false
    build_agent_pool_size = "S2"
  }
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

variable "git_repo_passwords" {
  type = list(string)
  sensitive = true
  default = null
}

variable "dns_name" {
  type = string
  default = "sampleapp.randomval-java-openlab.com"
}

variable "cert_name" {
  type = string
  default = "openlabcertificate"
  description = "name that will be used when storing your certificate in multiple services."
}

variable "shared_location" {
  type = string
  default = "westeurope"
  description = "location of the shared resources. Even though the shared resources, like Azure Front Door are Global, they still need to be placed in a resource group. This value will be used for the location of that resource group."
}

variable "use_self_signed_cert" {
  type = bool
  default = true
}

variable "cert_path" {
  type = string
  default = ""
}

variable "cert_password" {
  type = string
  sensitive = true
  default = ""
}