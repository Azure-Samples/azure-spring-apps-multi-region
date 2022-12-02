regions = [{
    location = "westeurope"
    location-short = "weu"
    config_server_git_setting = {
      uri          = "https://github.com/spring-petclinic/spring-petclinic-microservices-config.git"
      label        = "master"
      http_basic_auth = {
        username = "your-github-username"
      }
    }
  },
  {
    location = "eastus"
    location-short = "eus"
    config_server_git_setting = {
      uri          = "https://github.com/spring-petclinic/spring-petclinic-microservices-config.git"
      label        = "master"
      http_basic_auth = {
        username = "your-github-username"
      }
    }
}]

dns_name = "sampleapp.givermeims.com"

use_self_signed_cert = false
cert_path = "../wildcard_givermeims_com3.pfx"

apps = [
  {
    app_name = "api-gateway",
    needs_identity = false
    is_public = true
    needs_custom_domain = true
  },
  {
    app_name = "admin-service",
    needs_identity = false
    is_public = true
    needs_custom_domain = false
  },
  {
    app_name = "customers-service",
    needs_identity = true
    is_public = false
    needs_custom_domain = false
  },
  {
    app_name = "visits-service",
    needs_identity = true
    is_public = false
    needs_custom_domain = false
  },
  {
    app_name = "vets-service",
    needs_identity = true
    is_public = false
    needs_custom_domain = false
  }
]

environment_variables = {
  "SPRING_PROFILES_ACTIVE"     = "mysql"
}