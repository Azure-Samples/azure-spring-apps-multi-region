# Azure Spring Apps multi region reference architecture

This sample contains a Terraform template that deploys a working sample of the Azure architecture center reference architecture: [Multi region Azure Spring Apps reference architecture](https://learn.microsoft.com/azure/architecture/reference-architectures/microservices/spring-apps-multi-region). The reference architecture and sample show how to run an Azure Spring Apps workload in a multi region configuration. This allows for higher availability of the workload as well as global presence for the workload.

![Multi region Spring Apps architecture diagram](./images/multi-region-spring-apps-reference-architecture.png)

This sample also applies a proper reverse proxy configuration with [host name preservation](https://learn.microsoft.com/azure/architecture/best-practices/host-name-preservation). This means that cookies and AAD redirects will be working as expected.

## Features

This project framework provides the following features:

- Multi-region Spring Apps deployment with VNet integration
- Proper reverse proxy configuration for Application Gateway and Front Door with a custom domain
- Integration with Key Vault
- Integration with a MySQL database

## Getting Started

### Prerequisites

Before you begin, make sure you have the following available:

- Azure Subscription with Contributor access
- Azure Active Directory access
- optional: 
  - pfx certificate for your custom domain 
  - GitHub Personal Access Token 

> [NOTE!]
> There is also an option to install this infrastructure with a self-signed certificate. This certificate will be generated for you during the deployment. However, this setup should only be used in testing scenario's.
> Since Azure Front Door does not support self-signed certificates a host name override will take place, breaking some of the functionality of your backend applications. For production scenario's you should always apply [host name preservation](https://learn.microsoft.com/azure/architecture/best-practices/host-name-preservation).

To deploy the infrastructure, you can either make use of a locally installed environment, or you can make use of a pre-configured dev container.

When executing locally, make sure you have the following installed:

- Latest version of [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- Latest version of [AZ CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)

When using the dev container, either make sure you have [GitHub Codespaces](https://docs.github.com/codespaces/overview) enabled in your GitHub organization (you need at least a GitHub Teams license for this), or you can start up the dev container locally with the [Visual Studio Code Remote Containers](https://code.visualstudio.com/docs/remote/containers) extension.

### Installation

This sample can be set up in a test or a non-test setup and for Standard or Enterprise SKU.

- **test set up, Standard SKU**: In this case the Git PAT token is optional and a self-signed certificate is used. Walkthrough of this setup is found in the [install-test-standard.md](docs/install-test-standard.md) file.
- **test set up, Enterprise SKU**: In this case the Git PAT token is optional and a self-signed certificate is used. Walkthrough of this setup is found in the [install-test-enterprise.md](docs/install-test-enterprise.md) file.
- **production set up, Standard SKU**: In this case the Git PAT token is mandatory and a pfx certificate for your custom domain is used. Walkthrough of this setup is found in the [install-prod-standard.md](docs/install-prod-standard.md) file.
- **production set up, Enterprise SKU**: In this case the Git PAT token is mandatory and a pfx certificate for your custom domain is used. Walkthrough of this setup is found in the [install-prod-enterprise.md](docs/install-prod-enterprise.md) file.


### What you need to know about this setup

More info on how the terraform templates are build and how they operate can be found in the [docs](docs) folder of this repository. Best starting point is the [maintf.md](docs/maintf.md) file.

### Coming up

We are working on improving this sample. The ideas we have on improving:

- Create Bicep templates for the same setup (in progress)
- Make the database interchangeable for other types of databases (Cosmos DB as a first candidate)
- Make the application backend interchangeable. This multi-region setup with reverse proxies does not only apply to Azure Spring Apps, but also to other Azure PaaS services, like Azure App Service, Azure Kubernetes Service, ...
- Currently the apps in Azure Spring Apps are based on the Spring Petclinic sample, these apps should be better configurable.
- Include multi-zone support for Azure Spring Apps.

## Resources

- [Azure Architecture Center: Multi-region Azure Spring Apps reference architecture](https://learn.microsoft.com/azure/architecture/web-apps/spring-apps/architectures/spring-apps-multi-region)
- [Preserve the original HTTP host name between a reverse proxy and its back-end web application](https://learn.microsoft.com/azure/architecture/best-practices/host-name-preservation)
