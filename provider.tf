terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
  backend "local" {}
}

provider "azurerm" {
  features {}
subscription_id = "00a93b96-f5ee-4aa2-a363-cd2e65e808dc"
}
