#############
# VARIABLES #
#############

variable "prefix" {}

variable "state_sa_name" {}

variable "container_name" {}

variable "access_key" {
    type        = string
    sensitive   = true
}

variable "aks_private_dns_zone_name" {
default =  "privatelink.westus3.azmk8s.io"
}

variable "azurerm_log_analytics_workspace_id" {}

variable "network_plugin" {
default = "azure"
}

variable "pod_cidr" {
    default = null
}