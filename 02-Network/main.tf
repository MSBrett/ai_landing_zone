data "terraform_remote_state" "subnets" {
  backend = "azurerm"

  config = {
    storage_account_name = var.state_sa_name
    container_name       = var.container_name
    key                  = "subnets"
    access_key           = var.access_key
  }
}




