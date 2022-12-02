# Installation for test environments

For a test environment the use of a GitHub PAT token is optional. For a test environment no authentication for a spring apps config repo will be used and this repository can be a public one.
For a test environment you can also make use of a self-signed certificate.

To install this sample in your subscription for test environments:

## 1. Clone this repo

```bash
git clone https://github.com/Azure-Samples/azure-spring-apps-multi-region.git
cd azure-spring-apps-multi-region
```

## 2. Review the tfvars file

The [variables.tf](../tf-deploy/variables.tf) and [myvars.test.tfvars](../tf-deploy/myvars.test.tfvars) files in the tf-deploy directory contain the different variables you can configure. Update any values in the myvars.test.tfvars file to reflect the environment you would like to build. See [variables.md](variables.md) for an explanation of the different variables you can configure.

## 3. Log in to your Azure environment

```bash
az login
```

## 4. Execute the deployment

```bash
cd tf-deploy

terraform init -upgrade
terraform plan -var-file="myvars.test.tfvars" -out=plan.tfplan
terraform apply -auto-approve plan.tfplan
```
