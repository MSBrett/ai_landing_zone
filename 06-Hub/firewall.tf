# Firewall Subnet
# (Additional subnet for Azure Firewall, without NSG as per Firewall requirements)

resource "azurerm_firewall_policy" "fw_policy" {
  name                = "workload-firewall-policy"
  resource_group_name = azurerm_resource_group.workload_rg.name
  location            = azurerm_resource_group.workload_rg.location
  sku                 = "Basic"
}

output "fw_policy_id" {
  value = azurerm_firewall_policy.fw_policy.id
}


resource "azurerm_subnet" "firewall" {
  name                                      = "AzureFirewallSubnet"
  resource_group_name                       = azurerm_resource_group.workload_rg.name
  virtual_network_name                      = azurerm_virtual_network.workload_vnet.name
  address_prefixes                          = [cidrsubnet(azurerm_virtual_network.workload_vnet.address_space[0], 10, 3)]
  private_endpoint_network_policies_enabled = false
}

resource "azurerm_subnet" "firewall_management" {
  name                                      = "AzureFirewallManagementSubnet"
  resource_group_name                       = azurerm_resource_group.workload_rg.name
  virtual_network_name                      = azurerm_virtual_network.workload_vnet.name
  address_prefixes                          = [cidrsubnet(azurerm_virtual_network.workload_vnet.address_space[0], 10, 2)]
  private_endpoint_network_policies_enabled = false
}

resource "azurerm_firewall" "firewall" {
  name                = "${azurerm_virtual_network.workload_vnet.name}-firewall"
  resource_group_name = azurerm_resource_group.workload_rg.name
  location            = azurerm_resource_group.workload_rg.location
  firewall_policy_id  = azurerm_firewall_policy.fw_policy.id
  sku_name            = var.sku_name
  sku_tier            = var.sku_tier
  
  management_ip_configuration {
    name                 = "management"
    subnet_id            = azurerm_subnet.firewall_management.id
    public_ip_address_id = azurerm_public_ip.management.id
  }

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }

}

resource "azurerm_monitor_diagnostic_setting" "firewall" {
  name               = "firewall"
  target_resource_id = azurerm_firewall.firewall.id
  log_analytics_workspace_id = var.azurerm_log_analytics_workspace_id

  enabled_log {
   category = null 
   category_group = "allLogs"
  }

  metric {
    category = "AllMetrics"
  }
}

resource "azurerm_public_ip" "firewall" {
  name                 = "${azurerm_virtual_network.workload_vnet.name}-firewall-pip"
  resource_group_name  = azurerm_resource_group.workload_rg.name
  location             = azurerm_resource_group.workload_rg.location
  allocation_method    = "Static"
  sku                  = "Standard"
}

resource "azurerm_public_ip" "management" {
  name                 = "${azurerm_virtual_network.workload_vnet.name}-firewall-mgmt-pip"
  resource_group_name  = azurerm_resource_group.workload_rg.name
  location             = azurerm_resource_group.workload_rg.location
  allocation_method    = "Static"
  sku                  = "Standard"
}

resource "azurerm_subnet_route_table_association" "gateway_to_firewall" {
  subnet_id      = azurerm_subnet.gateway.id
  route_table_id = azurerm_route_table.gateway_to_firewall.id
}

resource "azurerm_route_table" "gateway_to_firewall" {
  name                          = "gateway-route-to-firewall"
  resource_group_name           = azurerm_resource_group.workload_rg.name
  location                      = azurerm_resource_group.workload_rg.location
  disable_bgp_route_propagation = true

  route {
    name                   = "gateway_route_to_firewall"
    address_prefix         = "10.0.0.0/8"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
  }
}