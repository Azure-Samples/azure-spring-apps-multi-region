# Installation for non-test environments

In case you install this sample in a non-test environment, usage of a private GitHub repository and authentication to it with a valid Git PAT token is advised. See [set up Git PAT](#set-up-git-pat) for steps to create a PAT token.

In case you install this sample in a non-test environment, you should also provide a properly signed pfx certificate for your custom domain.

To install this sample in your subscription:

## 1. Clone this repo

```bash
git clone https://github.com/Azure-Samples/azure-spring-apps-multi-region.git
cd azure-spring-apps-multi-region
```

## 2. Review the tfvars file

The [variables.tf](../tf-deploy/variables.tf) and [myvars.prod.tfvars](../tf-deploy/myvars.prod.tfvars) files in the tf-deploy directory contain the different variables you can configure. Update any values in the myvars.prod.tfvars file to reflect the environment you would like to build. See [variables.md](variables.md) for an explanation of the different variables you can configure.

Some of the variables are secret values, it is better to create environment variables for these and pass them along through the command line instead of putting them in the tfvars file.

```bash
GIT_REPO_PASSWORD="GH_PAT_your_created"
CERT_PASSWORD='password_of_your_certificate'
```

## 3. Log in to your Azure environment

```bash
az login
```

## 4. Execute the deployment

```bash
cd tf-deploy

terraform init -upgrade
terraform plan -var-file="myvars.prod.tfvars" -out=plan.tfplan -var='git_repo_passwords=["$GIT_REPO_PASSWORD","$GIT_REPO_PASSWORD"]' -var="cert_password=$CERT_PASSWORD"
terraform apply -auto-approve plan.tfplan
```

## 5. 1 extra manual step

In case you are deploying this sample with a certificate signed by a certificate authority, after the Terraform is deployed to your Azure environment, there is 1 extra manual step needed to verify the custom domain that is used in Azure Front Door.

If you check your Azure Front Door custom domain in the Azure Portal, you will notice the domain still needs to be verified. Terraform can only get you this far here. For verifying your custom domain, you can use a TXT record that you add to your DNS. Once you add this TXT record, the domain validity can be checked by Azure Front Door.

In the Azure Portal go to your Azure Front Door service > select `Domains` > Select the `Pending` message in the custom domain entry. This will show a flyout with details on the TXT record you need to add in your DNS configuration for the verification.

![](../images/Screenshot%20AFD.png)

Once the domain has been verified, you can connect to your application through your custom domain name.

> [NOTE!]
> In case you first see an error message when you go to your domain in the browser, give it a couple of minutes, it sometimes take about 5 minutes for the Azure Front Door route to take effect.

## 6. Test your setup

You can test your setup by going to your app through your custom domain in the browser. You should see the "Hurray~Your app is up and running!" page. 

## 7. Extra: Deploying the Spring Petclinic application

In case you want to deploy the spring petclinic micorservices application to your Spring Apps instances, use the guidance in [deploy-app.md](deploy-app.md)

## 8. Cleanup

To remove all the resources you have set up, run the below statement: 

```bash
terraform destroy -var-file="myvars.prod.tfvars" -var='git_repo_passwords=["$GIT_REPO_PASSWORD","$GIT_REPO_PASSWORD"]' -var="cert_password=$CERT_PASSWORD"
```

## Additional prerequisites
### Set up Git PAT

You can use the [Creating a personal access token](https://docs.github.com/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) from GitHub for creating a PAT token. 

In case you choose to create a classic PAT token, you should enable full repo scope access for your config repo.

In case you create a newer (beta) fine-grained PAt token, create it for your specific repository, and `read-only` access for `Contents`. 
