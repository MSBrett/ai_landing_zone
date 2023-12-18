
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

# OUTPUTS
# -------

output "workload_vnet_name" {
  value = azurerm_virtual_network.workload_vnet.name
}

output "workload_vnet_id" {
  value = azurerm_virtual_network.workload_vnet.id
}
