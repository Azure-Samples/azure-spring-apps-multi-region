# Terraform Variables

| param                  | Description                                                                                                                                                                                                                                                                                                          | Default value                          |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------- |
| `application_name`     | Optional. A name that will be prepended to all deployed resources.                                                                                                                                                                                                                                                   | asa-multiregion                        |
| `regions`              | Mandatory. An object representing the regions you wish to deploy to. See [region object](#regions-object) below for the structure of this.                                                                                                                                                                                          |                                        |
| `apps`              | Mandatory. A list of application objects. See [application object](#application-object) below for the structure of this.                                                                                                                                                                                          |                                        |
| `environment_variables`              | Mandatory. A map of environment variables for your spring apps. [myvars.test.tfvars](../tf-deploy/myvars.test.tfvars) contains a sample value.                                                                                                                                                                                         |                                        |
| `git_repo_passwords`   | Optional. Azure Spring Apps can be configured with a config server that is linked to a git repository. In case you are using a private git repository and you want to connect through Basic Auth, you will need to provide a github PAT password. For each region you want to deploy to this list of strings needs to contain the GitHub PAT for the git repository. You best pass this value through the command line. Don't put your PAT in the tfvars file! The [install-prod.md](install-prod.md) file explains how to pass in these tokens. |                                        |
| `dns_name`             | Optional. The domain name you want to use for your application. This should be same domain name as you use in your certificate. The default value is only there to give you an idea of what this variable should look like. You should always change this value.                                                     | `sampleapp.randomval-java-openlab.com` |
| `cert_name`            | Optional. Name to use when your certificate is stored in the different Azure Services.                                                                                                                                                                                                                               | `openlabcertificate`                   |
| `shared_location`      | Optional. The location to deploy any shared resources to. This variable will be used to create a separate resource group for the Azure Front Door service. The service itself is global, but it still needs a local resource group.                                                                                  | `westeurope`                           |
| `use_self_signed_cert` | Optional. Set to false in case you want to use a properly signed domain certificate.                                                                                                                                                                                                                                 | `true`                                 |
| `cert_path`            | Optional. When using your own properly signed certificate. The path on disk towards this certificate. This certificate will be uploaded to your Key Vault.                                                                                                                                                           | empty string                           |
| `cert_password`        | Optional. The password for the private key of your certificate.                                                                                                                                                                                                                                                      | empty string                           |

## Regions object

The variables make use of a regions object. This consists of the below parts:

| param               | Description                                                                                                                                                |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `location`          | Mandatory. The location for this region. For instance, `westeurope`.                                                                                       |
| `location-short`    | Mandatory. The short name of the region you want to deploy to. For instance `weu`. This short name will be appended to the name of all deployed resources. |
|`config_server_git_setting`| Mandatory. The config server settings. See [config_server_git_setting object](#config_server_git_setting-object) below for further explanation |

## config_server_git_setting object

| param               | Description                                                                                                                                                |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `uri`      | Mandatory. The uri to the git repository that holds the config data for this regions apps.                                                                            |
| `label`   | Optional. The branch of the git repository that holds the config data for this regions apps.                                                                         |
|`http_basic_auth`| Optional. In case you're using PAT token to authenticate, this object needs to be filled. See [http_basic_auth object](#http_basic_auth-object) below for further explanation |


## http_basic_auth object

| param               | Description                                                                                                                                                |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `username` | The username of the git repository that holds the config data for this regions apps.                                                                       |

## Application object

| param               | Description                                                                                                                                                |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
|`app_name`| Mandatory. The name of this app. For instance `api-gateway` or `customers-service`. |
|`needs_identity`| Mandatory. Boolean indicating whether a managed identity for the app will be created. This can be used when connecting to other services like Key Vault. |
|`is_public`| Mandatory. Boolean value indicating whether this app is a spring cloud api-gateway. Currently the template only supports 1 app as a gateway. |
|`needs_custom_domain`| Mandatory. Boolean value indicating  whether this is the app where your custom domain needs to be configured. The endpoint to this app will be used as a backend for the Application Gateway service. |

In the sample [myvars.test.tfvars](../tf-deploy/myvars.test.tfvars) and [myvars.prod.tfvars](../tf-deploy/myvars.prod.tfvars) files, there are a couple of apps defined. Api-gateway is configured with `is_public` and `needs_custom_domain` set to `true`. This means the applications will be exposed through Application Gateway through the api-gateway app in Spring Apps.

The `admin-service` however is only configured with `is_public` set to true. This app will only be accessible within the virtual network and not through the Application Gateway.


