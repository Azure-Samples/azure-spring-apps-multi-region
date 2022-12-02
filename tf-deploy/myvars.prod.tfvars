regions = [{
    location = "westeurope"
    location-short = "weu"
    config_server_git_setting = {
      uri          = "https://github.com/spring-petclinic/spring-petclinic-microservices-config.git"
      label        = "weu"
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
      label        = "eus"
      http_basic_auth = {
        username = "your-github-username"
      }
    }
}]

dns_name = "sampleapp.yourdomain.com"

use_self_signed_cert = false
cert_path = "../wildcard_yourdomain_com3.pfx"
