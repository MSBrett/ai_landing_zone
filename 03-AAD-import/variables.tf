#############
# VARIABLES #
#############

variable "aks_admin_group" {
  default = "App Admin Team"
}

variable "aks_user_group" {
  default = "App Dev Team"
}

# Storage Account Access Key
variable "access_key" {
  type        = string
  sensitive   = true
}