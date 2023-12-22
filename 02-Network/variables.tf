#############
# VARIABLES #
#############

variable "workload_location" {}

variable "tags" {
  type = map(string)

  default = {
    project = "ai-sandbox"
  }
}

variable "deployment_prefix" {
  default = "AI"
}

# Storage Account Access Key
variable "access_key" {
  type        = string
  sensitive   = true
}

variable "state_sa_name" {}

variable "container_name" {}

variable workload_address_space {
  default = "10.0.0.0/16"
}