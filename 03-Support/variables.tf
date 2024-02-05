variable "deployment_prefix" {
  default = "AI"
}

variable "access_key" {
  type        = string
  sensitive   = true
}

variable "state_sa_name" {}

variable "container_name" {}

variable "onpremise_gateway_public_ip_address" {}

variable security_center_contact_email {
  default = "abuse@microsoft.com"
}

variable security_center_contact_phone {
  default = "+1-425-555-1212"
}

variable azurerm_log_analytics_workspace_id {}
variable azurerm_log_analytics_workspace_rg {}
variable azurerm_log_analytics_workspace_name {}
variable azurerm_log_analytics_workspace_location {}