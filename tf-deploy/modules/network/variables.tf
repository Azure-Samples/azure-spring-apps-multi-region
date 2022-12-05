variable "resource_group" {
  type = string
}

variable "vnet_name" {
  type = string
}

variable "location" {
  type = string
}

variable "vnet_address_space" {
  type = list(string)
  default = ["10.1.0.0/16"]
}

variable "svc_subnet_address" {
  type = list(string)
  default = ["10.1.0.0/24"]
}

variable "apps_subnet_address" {
  type = list(string)
  default = ["10.1.1.0/24"]
}

variable "appgw_subnet_address" {
  type = list(string)
  default = ["10.1.2.0/24"]
}

variable "pe_subnet_address" {
  type = list(string)
  default = ["10.1.3.0/24"]
}