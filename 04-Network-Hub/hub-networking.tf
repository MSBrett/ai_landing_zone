
# Virtual Network for Hub
# -----------------------

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-hub"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.hub_location
  address_space       = ["10.0.0.0/16"]
  dns_servers         = null
  tags                = var.tags
}

# SUBNETS on Hub Network
# ----------------------

# Firewall Subnet
# (Additional subnet for Azure Firewall, without NSG as per Firewall requirements)
resource "azurerm_subnet" "firewall" {
  name                                      = "AzureFirewallSubnet"
  resource_group_name                       = azurerm_resource_group.rg.name
  virtual_network_name                      = azurerm_virtual_network.vnet.name
  address_prefixes                          = ["10.0.1.0/26"]
  private_endpoint_network_policies_enabled = false
}

resource "azurerm_subnet" "firewall_management" {
  name                                      = "AzureFirewallManagementSubnet"
  resource_group_name                       = azurerm_resource_group.rg.name
  virtual_network_name                      = azurerm_virtual_network.vnet.name
  address_prefixes                          = ["10.0.1.64/26"]
  private_endpoint_network_policies_enabled = false
}

# Bastion - Module creates additional subnet (without NSG), public IP and Bastion

# module "bastion" {
#   source = "./modules/bastion"

#   subnet_cidr          = "10.0.1.128/26"
#   virtual_network_name = azurerm_virtual_network.vnet.name
#   resource_group_name  = azurerm_resource_group.rg.name
#   location             = azurerm_resource_group.rg.location
# }

# Gateway Subnet 
# (Additional subnet for Gateway, without NSG as per requirements)
resource "azurerm_route_table" "gateway_to_firewall" {
  name                          = "gateway-route-to-firewall"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  disable_bgp_route_propagation = false

  route {
    name                   = "gateway_route_to_firewall"
    address_prefix         = "10.0.0.0/8"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
  }
}

resource "azurerm_subnet" "gateway" {
  name                                      = "GatewaySubnet"
  resource_group_name                       = azurerm_resource_group.rg.name
  virtual_network_name                      = azurerm_virtual_network.vnet.name
  address_prefixes                          = ["10.0.1.192/27"]
  private_endpoint_network_policies_enabled = false
}

resource "azurerm_subnet_route_table_association" "gateway_to_firewall" {
  subnet_id      = azurerm_subnet.gateway.id
  route_table_id = azurerm_route_table.gateway_to_firewall.id
}

# OUTPUTS
# -------

output "hub_vnet_name" {
  value = azurerm_virtual_network.vnet.name
}

output "hub_vnet_id" {
  value = azurerm_virtual_network.vnet.id
}
