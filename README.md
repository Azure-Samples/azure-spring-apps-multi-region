# Project Name

Fully automated deployment of a multi-region Azure Spring Apps instance, with proper reverse proxy configuration with [host name preservation](https://learn.microsoft.com/azure/architecture/best-practices/host-name-preservation).

## Features

This project framework provides the following features:

- Multi-region Spring Apps deployment
- Proper reverse proxy configuration for Application Gateway and Front Door with a custom domain
- Integration with Key Vault

## Getting Started

### Prerequisites

Before you begin, make sure you have the following available:

- Azure Subscription
- with Azure Active Directory access
- pfx certificate for your custom domain (optional)
- GH Personal Access Token

> [NOTE!]
> There is also an option to install this infrastructure with a self-signed certificate. This certificate will be generated for you during the deployment. However, this setup should only be used in testing scenario's. Since Azure Front Door does not support self-signed certificates a host name override will take place, breaking some of the functionality of your backend applications. For production scenario's you should always apply [host name preservation](https://learn.microsoft.com/azure/architecture/best-practices/host-name-preservation).

To deploy the infrastructure, you can either make use of a locally installed environment, or you can make use of a pre-configured dev container.

When executing locally, make sure you have the following installed:

- Terraform (latest)
- Azure CLI (latest)

When using the dev container, either make sure you have GitHub Codespaces enabled in your GitHub organization (you need at least a GitHub Teams license for this), or you can start up the dev container locally with the Visual Studio Code Remote Containers extension.

### Installation

To install this sample in your subscription:

- review the [myvars.tfvars](tf-deploy/myvars.tfvars) file in the tf-deploy directory and update any values to reflect the environment you would like to build. See below for an explanation of the different variables you can configure.
- execute:

```bash
GIT_REPO_PASSWORD="GH_PAT_your_created"
CERT_PASSWORD='password_of_your_certificate'

cd tf-deploy

az login

terraform init -upgrade
terraform plan -var-file="myvars.tfvars" -out=plan.tfplan var='git_repo_passwords=["$GIT_REPO_PASSWORD","$GIT_REPO_PASSWORD"]' var="cert_password=$CERT_PASSWORD"
terraform apply -auto-approve plan.tfplan
```

### Variables

TODO: explanation of variables

### What you need to know about this setup

TODO: more explanation on the sample

### Coming up

We are working on improving this sample. The ideas we have on improving:

- Create Bicep templates for the same setup (in progress)
- Make the database interchangeable for other types of databases (Cosmos DB as a first candidate)
- Make the application backend interchangeable. This multi-region setup with reverse proxies does not only apply to Azure Spring Apps, but also to other Azure PaaS services, like Azure App Service, Azure Kubernetes Service, ...
- Currently the apps in Azure Spring Apps are based on the Spring Petclinic sample, these apps should be better configurable.
- Include multi-zone support for Azure Spring Apps.

## Resources

- [Azure Architecture Center: Multi-region Azure Spring Apps reference architecture(coming up)](article coming up)
- [Preserve the original HTTP host name between a reverse proxy and its back-end web application](https://learn.microsoft.com/azure/architecture/best-practices/host-name-preservation)
