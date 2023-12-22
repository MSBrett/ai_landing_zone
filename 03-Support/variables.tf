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