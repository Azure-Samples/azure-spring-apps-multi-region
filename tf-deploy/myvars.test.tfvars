regions = [{
    location = "westeurope"
    location-short = "weu"
    config_server_git_setting = {
      uri          = "https://github.com/spring-petclinic/spring-petclinic-microservices-config.git"
      label        = "weu"
    }
  },
  {
    location = "eastus"
    location-short = "eus"
    config_server_git_setting = {
      uri          = "https://github.com/spring-petclinic/spring-petclinic-microservices-config.git"
      label        = "eus"
    }
}]

dns_name = "sampleapp.yourdomain.com"

use_self_signed_cert = true
