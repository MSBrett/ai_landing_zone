#############
# VARIABLES #
#############

variable "tags" {
  type = map(string)

  default = {
    project = "aoai-lz"
  }
}

variable "ai_location" {
    default = "EastUS"
}

variable "state_sa_name" {}

variable "lz_prefix" {}

variable "container_name" {}

variable "access_key" {
  type        = string
  sensitive   = true
}

variable "azurerm_log_analytics_workspace_id" {}

variable "aoai_sku" {
  type        = string
  default     = "S0"
  description = "Specifies the SKU Name for this Cognitive Service Account. Possible values are `F0`, `F1`, `S0`, `S`, `S1`, `S2`, `S3`, `S4`, `S5`, `S6`, `P0`, `P1`, `P2`, `E0` and `DC0`. Default to `S0`."
}

variable "cognitive_services_sku" {
  type        = string
  default     = "S0"
  description = "Specifies the SKU Name for this Cognitive Service Account. Possible values are `F0`, `F1`, `S0`, `S`, `S1`, `S2`, `S3`, `S4`, `S5`, `S6`, `P0`, `P1`, `P2`, `E0` and `DC0`. Default to `S0`."
}

variable "search_sku" {
  type        = string
  description = "The sku name of the Azure Search service."
  default     = "basic"
}

variable "search_replica_count" {
  type        = number
  description = "The number of replicas in the service."
  default     = 1
}

variable "search_partition_count" {
  type        = number
  description = "The number of partitions in the service."
  default     = 1
}