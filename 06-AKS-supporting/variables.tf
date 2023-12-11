#############
# VARIABLES #
#############

variable "prefix" {}

# Storage Account Access Key
variable "access_key" {
  type        = string
  sensitive   = true
}

variable "state_sa_name" {}

variable "container_name" {}

variable "admin_password" {
  default = "change me"
}

variable "admin_username" {
  sensitive = true
  default = "sysadmin"
}


# The Public Domain for the public dns zone, that is used to register the hostnames assigned to the workloads hosted in AKS; if empty the dns zone not provisioned.
variable "public_domain" {
    description = "The Public Domain for the public dns zone, that is used to register the hostnames assigned to the workloads hosted in AKS; if empty the dns zone not provisioned."
    default = ""
}

variable "onpremise_gateway_public_ip_address" {}