
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

resource "azurerm_subnet_nat_gateway_association" "aksSubnet" {
  subnet_id      = azurerm_subnet.aks.id
  nat_gateway_id = data.terraform_remote_state.support.outputs.nat_gateway_id
}

# # Associate Route Table to AKS Subnet
resource "azurerm_route_table" "aks_route_table" {
  name                          = "aks-route-table"
  resource_group_name           = data.terraform_remote_state.network.outputs.workload_rg_name
  location                      = data.terraform_remote_state.network.outputs.workload_rg_location
  disable_bgp_route_propagation = false
  /*
  route {
    name                       = "default"
    address_prefix             = "0.0.0.0/0"
    next_hop_type              = "VirtualNetworkGateway"
  }
  */
}

resource "azurerm_subnet_route_table_association" "rt_association" {
  subnet_id      = azurerm_subnet.aks.id
  route_table_id = azurerm_route_table.aks_route_table.id
}

output "aks_route_table_id"{
  value = azurerm_route_table.aks_route_table.id
}

resource "azurerm_role_assignment" "aks_to_rt" {
  for_each             = azurerm_user_assigned_identity.mi_aks_cp
  scope                = azurerm_route_table.aks_route_table.id
  role_definition_name = "Contributor"
  principal_id         = each.value.principal_id
}

