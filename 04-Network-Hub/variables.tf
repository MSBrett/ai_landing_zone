#############
# VARIABLES #
#############

variable "hub_location" {}

variable "tags" {
  type = map(string)

  default = {
    project = "lz-hub"
  }
}

variable "hub_prefix" {
}

variable "sku_name" {
  default = "AZFW_VNet"
}

variable "sku_tier" {
  default = "Basic"
}

variable "vm_size" {
  default = "Standard_D2s_v3"
}


variable "onpremise_address_space" {}

variable "onpremise_gateway_public_ip_address" {}

variable "azurerm_log_analytics_workspace_id" {}

# Storage Account Access Key
variable "access_key" {
  type        = string
  sensitive   = true
}