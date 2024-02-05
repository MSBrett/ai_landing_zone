# This section create a subnet for apim along with an associated NSG.
# "Here be dragons!" <-- Must elaborate

resource "azurerm_subnet" "apim" {
  name                                      = "apimSubnet"
  resource_group_name                       = data.terraform_remote_state.network.outputs.workload_rg_name
  virtual_network_name                      = data.terraform_remote_state.network.outputs.workload_vnet_name
  address_prefixes                          = [data.terraform_remote_state.subnets.outputs.apimSubnet]
  private_endpoint_network_policies_enabled = true
  service_endpoints = [ "Microsoft.KeyVault", "Microsoft.Storage", "Microsoft.Sql", "Microsoft.AzureCosmosDB", "Microsoft.EventHub" ]
}

output "apim_subnet_id" {
  value = azurerm_subnet.apim.id
}

resource "azurerm_network_security_group" "apim_nsg" {
  name                = "${data.terraform_remote_state.network.outputs.workload_vnet_name}-${azurerm_subnet.apim.name}-nsg" 
  resource_group_name = data.terraform_remote_state.network.outputs.workload_rg_name
  location            = data.terraform_remote_state.network.outputs.workload_rg_location
}

resource "azurerm_subnet_network_security_group_association" "apim_subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.apim.id
  network_security_group_id = azurerm_network_security_group.apim_nsg.id
}


# Rule 1: Inbound TCP rule for Client communication to API Management
resource "azurerm_network_security_rule" "rule_stv2" {
  name                        = "rule-stv2"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443"]
  source_address_prefix       = "*"
  destination_address_prefix  = "Internet"
  description                 = "Client communication to API Management"
  resource_group_name         = data.terraform_remote_state.network.outputs.workload_rg_name
  network_security_group_name = azurerm_network_security_group.apim_nsg.name
}

resource "azurerm_network_security_rule" "rule_stv3_1" {
  name                        = "rule-stv3_1"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3443"           # Corrected to the required destination port (3443)
  source_address_prefix       = "ApiManagement"  # Required source service tag
  destination_address_prefix  = "VirtualNetwork" # Required destination service tag
  description                 = "Management endpoint for Azure portal and PowerShell"
  resource_group_name         = data.terraform_remote_state.network.outputs.workload_rg_name
  network_security_group_name = azurerm_network_security_group.apim_nsg.name
}

# Rule 3: Inbound TCP rule for Azure Infrastructure Load Balancer
resource "azurerm_network_security_rule" "rule_lb" {
  name                        = "rule-lb"
  priority                    = 103
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "6390"
  source_address_prefix       = "*"
  destination_address_prefix  = "AzureLoadBalancer"
  description                 = "Azure Infrastructure Load Balancer"
  resource_group_name         = data.terraform_remote_state.network.outputs.workload_rg_name
  network_security_group_name = azurerm_network_security_group.apim_nsg.name
}

# Rule 2: Inbound TCP rule for Management endpoint for Azure portal and PowerShell
resource "azurerm_network_security_rule" "rule_stv1" {
  name                        = "rule-stv1"
  priority                    = 102
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3443"
  source_address_prefix       = "*"
  destination_address_prefix  = "ApiManagement"
  description                 = "Management endpoint for Azure portal and PowerShell"
  resource_group_name         = data.terraform_remote_state.network.outputs.workload_rg_name
  network_security_group_name = azurerm_network_security_group.apim_nsg.name
}

resource "azurerm_network_security_rule" "rule_stv3" {
  name                        = "rule-stv3"
  priority                    = 104
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3443"
  source_address_prefix       = "*"
  destination_address_prefix  = "ApiManagement"
  description                 = "Management endpoint for Azure portal and PowerShell"
  resource_group_name         = data.terraform_remote_state.network.outputs.workload_rg_name
  network_security_group_name = azurerm_network_security_group.apim_nsg.name
}

# Rule 4: Outbound TCP rule for Dependency on Azure Storage
resource "azurerm_network_security_rule" "rule_storage" {
  name                        = "rule-storage"
  priority                    = 200
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "Storage"
  description                 = "Dependency on Azure Storage"
  resource_group_name         = data.terraform_remote_state.network.outputs.workload_rg_name
  network_security_group_name = azurerm_network_security_group.apim_nsg.name
}

# Rule 5: Outbound TCP rule for Access to Azure SQL endpoints
resource "azurerm_network_security_rule" "rule_sql" {
  name                        = "rule-sql"
  priority                    = 201
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "1433"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "SQL"
  description                 = "Access to Azure SQL endpoints"
  resource_group_name         = data.terraform_remote_state.network.outputs.workload_rg_name
  network_security_group_name = azurerm_network_security_group.apim_nsg.name
}

# Rule 6: Outbound TCP rule for Access to Azure Key Vault
resource "azurerm_network_security_rule" "rule_kv" {
  name                        = "rule-kv"
  priority                    = 202
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "AzureKeyVault"
  description                 = "Access to Azure Key Vault"
  resource_group_name         = data.terraform_remote_state.network.outputs.workload_rg_name
  network_security_group_name = azurerm_network_security_group.apim_nsg.name
}

# # Associate Route Table to apim Subnet

resource "azurerm_route_table" "apim_route_table" {
  name                          = "apim-route-table"
  resource_group_name           = data.terraform_remote_state.network.outputs.workload_rg_name
  location                      = data.terraform_remote_state.network.outputs.workload_rg_location

  route {
    name                   = "route-apim"
    address_prefix         = "ApiManagement"
    next_hop_type          = "Internet"
  }
}

resource "azurerm_subnet_route_table_association" "apim_subnet_rt_association" {
  subnet_id      = azurerm_subnet.apim.id
  route_table_id = azurerm_route_table.apim_route_table.id
}

resource "azurerm_public_ip" "apim" {
  name                = "apim-${random_pet.funny_name.id}-${random_integer.deployment.result}-pip"
  location            = data.terraform_remote_state.network.outputs.workload_rg_location
  resource_group_name = data.terraform_remote_state.network.outputs.workload_rg_name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "apim-${random_pet.funny_name.id}-${random_integer.deployment.result}"
}

resource "azurerm_api_management" "apim" {
  name                = "apim-${random_pet.funny_name.id}-${random_integer.deployment.result}"
  location            = data.terraform_remote_state.network.outputs.workload_rg_location
  resource_group_name = data.terraform_remote_state.network.outputs.workload_rg_name
  publisher_name      = "Microsoft"
  publisher_email     = "info@microsoft.com"
  public_ip_address_id = azurerm_public_ip.apim.id

  sku_name = "Developer_1"
  #sku_name = "Consumption_0"
  
  virtual_network_type = "Internal"

  virtual_network_configuration {
    subnet_id = azurerm_subnet.apim.id
  }

  identity {
    type = "SystemAssigned"
  }

  policy {
    xml_content = <<XML
    <policies>
      <inbound />
      <backend />
      <outbound />
      <on-error />
    </policies>
  XML
  }

  timeouts {
    create = "1h"
    update = "1h"
    delete = "1h"
  }

  depends_on = [ azurerm_subnet_network_security_group_association.apim_subnet_nsg_association ]
}


output "apim_principal_id" {
  value = azurerm_api_management.apim.identity[0].principal_id
}

output "apim_name" {
  value = azurerm_api_management.apim.name
}

# Create DNS Zone and register it with the VNET
resource "azurerm_private_dns_zone" "private_dns_zone" {
  name                = "azure-api.net"
  resource_group_name = data.terraform_remote_state.network.outputs.workload_rg_name
}

resource "azurerm_private_dns_a_record" "private_dns_a_record" {
  name                = "apim-${random_integer.deployment.result}"
  zone_name           = azurerm_private_dns_zone.private_dns_zone.name
  resource_group_name = data.terraform_remote_state.network.outputs.workload_rg_name
  ttl                 = 300
  records             = [azurerm_api_management.apim.private_ip_addresses[0]]
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_zone_link_vnet" {
  name                  = "vnet_workload_link_to_apim"
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone.name
  resource_group_name   = data.terraform_remote_state.network.outputs.workload_rg_name
  virtual_network_id    = data.terraform_remote_state.network.outputs.workload_vnet_id
  registration_enabled  = false
}
