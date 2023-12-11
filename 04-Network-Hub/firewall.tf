resource "azurerm_firewall" "firewall" {
  name                = "${azurerm_virtual_network.vnet.name}-firewall"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  firewall_policy_id  = module.firewall_rules_hub.fw_policy_id
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
  name                 = "${azurerm_virtual_network.vnet.name}-firewall-pip"
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  allocation_method    = "Static"
  sku                  = "Standard"
}

resource "azurerm_public_ip" "management" {
  name                 = "${azurerm_virtual_network.vnet.name}-firewall-mgmt-pip"
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  allocation_method    = "Static"
  sku                  = "Standard"
}

module "firewall_rules_hub" {
  source = "./modules/hub-fw-rules"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  firewall_public_ip_address = azurerm_public_ip.firewall.ip_address
  onpremise_gateway_public_ip_address = var.onpremise_gateway_public_ip_address
  vm_private_ip_address = module.create_linuxsserver.vm_private_ip_address
}
