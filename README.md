# Hub and Spoke with Terraform

All support files to build hub and spoke vnet design for Azure

# instructions

from Azure Cloud Shell
- terraform init
- terraform plan
- terraform apply

## output
Initializing your account for Cloud Shell...\
Requesting a Cloud Shell.Succeeded.
Connecting terminal...

Welcome to Azure Cloud Shell

Type "az" to use Azure CLI 2.0
Type "help" to learn about Cloud Shell

raj@Azure:$ cd clouddrive
raj@Azure:/clouddrive$ mkdir hub-spoke
raj@Azure:/clouddrive$ cd hub-spoke/
raj@Azure:/clouddrive/hub-spoke$ code main.tf
raj@Azure:/clouddrive/hub-spoke$ code variables.tf
raj@Azure:/clouddrive/hub-spoke$ pwd
/home/raj/clouddrive/hub-spoke
raj@Azure:/clouddrive/hub-spoke$ code on-prem.tf
raj@Azure:/clouddrive/hub-spoke$ code hub-vnet.tf
raj@Azure:/clouddrive/hub-spoke$ code hub-nva.tf
raj@Azure:/clouddrive/hub-spoke$ code spoke1.tf
raj@Azure:/clouddrive/hub-spoke$ code spoke2.tf

raj@Azure:/clouddrive/hub-spoke$ ls
hub-nva.tf  hub-vnet.tf  main.tf  on-prem.tf  spoke1.tf  spoke2.tf  variables.tf
raj@Azure:~/clouddrive/hub-spoke$


# more info
Based on the following tutorial
https://docs.microsoft.com/en-us/azure/terraform/terraform-hub-spoke-introduction
