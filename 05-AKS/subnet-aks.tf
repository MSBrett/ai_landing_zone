
# This section create a subnet for AKS along with an associated NSG.
# "Here be dragons!" <-- Must elaborate

resource "azurerm_subnet" "aks" {
  name                                      = "aksSubnet"
  resource_group_name                       = data.terraform_remote_state.network.outputs.workload_rg_name
  virtual_network_name                      = data.terraform_remote_state.network.outputs.workload_vnet_name
  address_prefixes                          = [data.terraform_remote_state.subnets.outputs.aksSubnet]
  private_endpoint_network_policies_enabled = true

  lifecycle {
    ignore_changes = [
      service_endpoints
    ]
  }
}

output "aks_subnet_id" {
  value = azurerm_subnet.aks.id
}

resource "azurerm_network_security_group" "aks_nsg" {
  name                = "${data.terraform_remote_state.network.outputs.workload_vnet_name}-${azurerm_subnet.aks.name}-nsg" 
  resource_group_name = data.terraform_remote_state.network.outputs.workload_rg_name
  location            = data.terraform_remote_state.network.outputs.workload_rg_location
}

resource "azurerm_subnet_network_security_group_association" "subnet" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks_nsg.id
}

output "aks_nsg_id"{
  value = azurerm_network_security_group.aks_nsg.id
}


