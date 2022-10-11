variable "resource_group" {
  type = string
}

variable "asa_name" {
  type = string
}

variable "location" {
  type = string
}

variable "app_subnet_id" {
  type = string
}

variable "cidr_ranges" {
  type = list(string)
  default = ["10.4.0.0/16", "10.5.0.0/16", "10.3.0.1/16"]
}

variable "svc_subnet_id" {
  type = string
}

variable "git_repo_uri" {
  type = string
}

variable "git_repo_branch" {
  type = string
  default = "main"
}

variable "git_repo_username" {
  type = string
}

variable "git_repo_password" {
  type = string
  sensitive = true
}

variable "virtual_network_id" {
  type = string
}

variable "cert_id" {
  type = string
}

variable "cert_name" {
  type = string
}