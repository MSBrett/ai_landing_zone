# Virtual Network
data "azurerm_firewall" "firewall" {
  name                = data.terraform_remote_state.existing-hub.outputs.firewall_name
  resource_group_name = data.terraform_remote_state.existing-hub.outputs.hub_rg_name
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-ai"
  resource_group_name = azurerm_resource_group.ai_rg.name
  location            = azurerm_resource_group.ai_rg.location
  address_space       = ["10.2.0.0/23"]
  dns_servers         = null
  tags                = var.tags
}

output "lz_vnet_name" {
  value = azurerm_virtual_network.vnet.name
}

output "lz_vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

# # Create Route Table for Landing Zone
# (All subnets in the landing zone will need to connect to this Route Table)

resource "azurerm_route_table" "route_table" {
  name                          = "default-route-to-firewall"
  resource_group_name           = azurerm_resource_group.ai_rg.name
  location                      = azurerm_resource_group.ai_rg.location
  disable_bgp_route_propagation = false

  route {
    name                   = "default_route_to_firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = data.azurerm_firewall.firewall.ip_configuration[0].private_ip_address
  }
}

output "lz_rt_id" {
  value = azurerm_route_table.route_table.id
}


# This section create a subnet for services along with an associated NSG.
# "Here be dragons!" <-- Must elaborate

resource "azurerm_subnet" "service_subnet" {
  name                                      = "serviceSubnet"
  resource_group_name                       = azurerm_resource_group.ai_rg.name
  virtual_network_name                      = azurerm_virtual_network.vnet.name
  address_prefixes                          = ["10.2.1.0/27"]
  private_endpoint_network_policies_enabled = true

}

output "serviceSubnet_subnet_id" {
  value = azurerm_subnet.service_subnet.id
}

resource "azurerm_network_security_group" "service_subnet_nsg" {
  name                = "${azurerm_virtual_network.vnet.name}-${azurerm_subnet.service_subnet.name}-nsg"
  resource_group_name = azurerm_resource_group.ai_rg.name
  location            = azurerm_resource_group.ai_rg.location
}

resource "azurerm_subnet_network_security_group_association" "service_subnet_subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.service_subnet.id
  network_security_group_id = azurerm_network_security_group.service_subnet_nsg.id
}

# # Associate Route Table to service Subnet
resource "azurerm_subnet_route_table_association" "service_subnet_rt_association" {
  subnet_id      = azurerm_subnet.service_subnet.id
  route_table_id = azurerm_route_table.route_table.id
}
