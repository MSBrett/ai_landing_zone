#############
# VARIABLES #
#############

variable "tags" {
  type = map(string)

  default = {
    project = "spoke-lz"
  }
}

variable "lz_prefix" {}

# Used to retrieve outputs from other state files.
# The "access_key" variable is sensitive and should be passed using
# a .TFVARS file or other secure method.

variable "state_sa_name" {
  default = "xxx"
}

variable "container_name" {
  default = "tfstate"
}

# Storage Account Access Key
variable "access_key" {
  type        = string
  sensitive   = true
}