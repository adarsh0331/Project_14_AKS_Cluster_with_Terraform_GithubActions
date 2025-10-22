terraform {
  required_version = ">= 1.5.0"

    backend "azurerm" {
    resource_group_name  = "adarsh_group"         # existing RG where your storage account is
    storage_account_name = "tfstateaccountmind"  # your existing Storage Account name
    container_name       = "tfstate"            # your blob container for tfstate
    key                  = "terraform.tfstate"  # file name inside container
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

provider "azurerm" {
  features {}
subscription_id = "00a93b96-f5ee-4aa2-a363-cd2e65e808dc"
}
