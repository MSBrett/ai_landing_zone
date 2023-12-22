resource "azurerm_resource_group" "workload_rg" {
  name     = "${var.deployment_prefix}-SANDBOX"
  location = var.workload_location
}

output "workload_rg_location" {
  value = azurerm_resource_group.workload_rg.location
}

output "workload_rg_name" {
  value = azurerm_resource_group.workload_rg.name
}