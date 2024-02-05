
# Virtual Network for Hub
# -----------------------

resource "azurerm_virtual_network" "workload_vnet" {
  name                = "workload-vnet"
  resource_group_name = azurerm_resource_group.workload_rg.name
  location            = var.workload_location
  address_space       = [data.terraform_remote_state.subnets.outputs.WorkloadAddressSpace]
  dns_servers         = null
  tags                = var.tags
}

resource "azurerm_network_ddos_protection_plan" "ddos_plan" {
  name                = "ddos-protection-plan"
  location            = azurerm_resource_group.workload_rg.location
  resource_group_name = azurerm_resource_group.workload_rg.name
}

# OUTPUTS
# -------

output "workload_vnet_name" {
  value = azurerm_virtual_network.workload_vnet.name
}

output "workload_vnet_id" {
  value = azurerm_virtual_network.workload_vnet.id
}

output "ddos_plan_name" {
  value = azurerm_network_ddos_protection_plan.ddos_plan.name
}

output "ddos_plan_id" {
  value = azurerm_network_ddos_protection_plan.ddos_plan.id
}