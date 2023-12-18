resource "azurerm_subnet" "service_subnet" {
  name                                      = "serviceSubnet"
  resource_group_name                       = data.terraform_remote_state.network.outputs.workload_rg_name
  virtual_network_name                      = data.terraform_remote_state.network.outputs.workload_vnet_name
  address_prefixes                          = [data.terraform_remote_state.subnets.outputs.serviceSubnet]
  private_endpoint_network_policies_enabled = true

}

output "serviceSubnet_subnet_id" {
  value = azurerm_subnet.service_subnet.id
}

resource "azurerm_network_security_group" "service_subnet_nsg" {
  name                = "${data.terraform_remote_state.network.outputs.workload_vnet_name}-${azurerm_subnet.service_subnet.name}-nsg"
  resource_group_name = data.terraform_remote_state.network.outputs.workload_rg_name
  location            = data.terraform_remote_state.network.outputs.workload_rg_location
}

resource "azurerm_subnet_network_security_group_association" "service_subnet_subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.service_subnet.id
  network_security_group_id = azurerm_network_security_group.service_subnet_nsg.id
}