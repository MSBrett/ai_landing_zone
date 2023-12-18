#############
# VARIABLES #
#############

variable "workload_location" {}

variable "tags" {
  type = map(string)

  default = {
    project = "lz-hub"
  }
}

variable "deployment_prefix" {
  default = "LZ"
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


variable "onpremise_address_space" {
  default = "192.168.0.0/16"
}

variable "onpremise_gateway_public_ip_address" {
  default = "1.2.3.4"
}

variable "azurerm_log_analytics_workspace_id" {}

# Storage Account Access Key
variable "access_key" {
  type        = string
  sensitive   = true
}