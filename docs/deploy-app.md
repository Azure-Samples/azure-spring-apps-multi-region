# Deploy spring petclinic application

Use a clone of the [spring petclinic application in Azure Samples](https://github.com/Azure-Samples/spring-petclinic-microservices). The [labstarter branch](https://github.com/Azure-Samples/spring-petclinic-microservices/tree/labstarter) of this repository has a clean version that is tested with Azure Spring Apps without extra Azure packages. 

1. Perform a build of the code:

```bash
mvn clean package -DskipTests
```

1. Create environment variables for your Spring Apps service name and the resource group of your first region.

```bash
SPRING_APPS_SERVICE=<the name of the spring apps service in region 1 you created with Terraform>
RESOURCE_GROUP=<the name of the resource group for region 1 you created with Terraform>
```
1. Deploy each of the microservices. Execute the below for the `api-gateway`, `admin-server`, `customers-service`, `vets-service` and `visits-service`: 

```bash
az spring app deploy \
         --service $SPRING_APPS_SERVICE \
         --resource-group $RESOURCE_GROUP \
         --name <app name> \
         --no-wait \
         --artifact-path spring-petclinic-<app name>/target/spring-petclinic-<app name>-2.7.6.jar
```

    You will need to execute the above for each app. 

1. Next reset the environment variables to the names of your second region and repeat the deploy of each app to this second region.

1. In case you want to properly see data in your apps, also update your config repository to use the correct connection string info and username password combo for your mysql database. For this in the config repo change:

```yaml
    url: jdbc:mysql://localhost:3306/db?useSSL=false
    username: root
    password: petclinic
```

    to: 

```yaml
    url: jdbc:mysql://<your-mysql-server-name>.mysql.database.azure.com:3306/<your-mysql-database-name>?useSSL=true
    username: myadmin@<your-mysql-server-name>
    password: <myadmin-password>
```
