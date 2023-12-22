#############
# VARIABLES #
#############

variable workload_address_space {
  type = string
}

variable "state_sa_name" {}

variable "container_name" {}

variable "access_key" {
  type        = string
  sensitive   = true
}
