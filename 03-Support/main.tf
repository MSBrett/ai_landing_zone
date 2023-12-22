########
# DATA #
########

# Data From Existing Infrastructure

data "terraform_remote_state" "aad" {
  backend = "azurerm"

  config = {
    storage_account_name = var.state_sa_name
    container_name       = var.container_name
    key                  = "aad"
    access_key           = var.access_key
  }
}

data "terraform_remote_state" "network" {
  backend = "azurerm"
  config = {
    storage_account_name = var.state_sa_name
    container_name       = var.container_name
    key                  = "network"
    access_key           = var.access_key
  }
}

data "terraform_remote_state" "subnets" {
  backend = "azurerm"
  config = {
    storage_account_name = var.state_sa_name
    container_name       = var.container_name
    key                  = "subnets"
    access_key           = var.access_key
  }
}

data "azurerm_client_config" "current" {}

resource "random_integer" "deployment" {
  min = 10000
  max = 99999
}

output "deployment_suffix" {
  value = random_integer.deployment.result
}

resource "random_pet" "funny_name" {
  length    = 2
  separator = "-"
}

output "funny_name" {
  value = random_pet.funny_name.id
}








