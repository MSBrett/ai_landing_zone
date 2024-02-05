terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.83.0"
    }
    random = {
      version = ">=3.0"
    }

    azapi = {
      source  = "Azure/azapi"
      version = ">=1.12.0"
    }
  }
  backend "azurerm" {
    # resource_group_name  = ""   # Partial configuration, provided during "terraform init"
    # storage_account_name = ""   # Partial configuration, provided during "terraform init"
    # container_name       = ""   # Partial configuration, provided during "terraform init"
    key                  = "support"
  }
}

provider "azurerm" {
  features {}
}
