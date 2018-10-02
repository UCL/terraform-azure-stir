## Install Azure CLI

## Install Terraform

## Configure Terraform access to Azure
- Query your Azure account to get a list of subscription and tenant ID values:
```bash
az account show --query "{subscriptionId:id, tenantId:tenantId}"
```
- Note the `subscriptionId` and `tenantId` for future use.
- Set the environment variable `SUBSCRIPTION_ID` to the subscription ID returned by the `az account show` command. In Bash, this would be:
```bash
export SUBSCRIPTION_ID=your_subscription_id
```
- Create an Azure service prinicple for Terraform to use:
```bash
az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/${SUBSCRIPTION_ID}"
```
- Make a note of the `appId` and `password`

## Configure Terraform environment variables
- Copy `var_values.tfvars.example` to `var_values.tfvars`
- Edit `var_values.tfvars` such that `YOUR_SUBSCRIPTION_ID_HERE`, `YOUR_APPLICATION_ID_HERE`,`YOUR_SECRET_KEY_HERE` and `YOUR_TENANT_ID_HERE` are replaced by your `subscriptionId`, `appId`, `password` and `tenantId` respectively.

## Running the Terraform script
- Initalise Terraform:
```shell
terraform init
```
- To preview the actions that Terraform will take, run:
```shell
terraform plan -var-file var_values.tfvars
```
- To run the script:
```shell 
terraform apply -var-file var_values.tfvars
```
- If this succeeded, a virtual machine will be running on Azure.
- Find the public IP address of the machine:
```shell
az vm show --resource-group stirGroup --name stirVM -d --query [publicIps] --o tsv
```
- Make a note of the IP address.
- To access the machine via ssh:
```shell
ssh USERNAME@PUBLICIP
```
where `USERNAME` is the value set for `vm_username` (default: `stiruser`) and `PUBLICIP` is the public IP address found with the previous command.

## Removing the infrastructure
```shell
terraform destroy
```
To avoid incurring unexpected costs, it is highly recommended that you check the Azure web portal to ensure that all resources have successfully been destroyed.

## Troubleshooting
If you get an error related to `SkuNotAvailable`, try to display all available machine types and see if the chosen machine exists in the region:
```
az vm list-skus --output table
```