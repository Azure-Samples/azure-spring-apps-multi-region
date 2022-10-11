variable "application_name" {
  type        = string
  description = "The name of your application"
  default     = "asa-multiregion"
}

variable "regions" {
  type = list(object({
    location = string
    location-short = string
    git_repo_uri = string
    git_repo_branch = string
    git_repo_username = string
  }))
  description = "the regions you want the Azure Spring Apps backends to be deployed to."
}

variable "git_repo_passwords" {
  type = list(string)
  sensitive = true
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