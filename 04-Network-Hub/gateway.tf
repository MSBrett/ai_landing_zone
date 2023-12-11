# vNet Gateway Public IP
resource "azurerm_public_ip" "vnet_gateway_pip" {
  name                = "vnet-hub-gateway-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.hub_location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# onPremise Gateway
resource "azurerm_local_network_gateway" "onpremise" {
  name                = "onpremise-gateway"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.hub_location
  gateway_address     = var.onpremise_gateway_public_ip_address
  address_space       = var.onpremise_address_space
}

# vNet Gateway
resource "azurerm_virtual_network_gateway" "vnet_gateway" {
  name                = "vnet-hub-gateway"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.hub_location
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw1"

  ip_configuration {
    name                 = "config-name"
    subnet_id            = azurerm_subnet.gateway.id
    public_ip_address_id = azurerm_public_ip.vnet_gateway_pip.id
  }

  timeouts {
    create = "60m"
  }
}
