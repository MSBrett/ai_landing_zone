resource "azurerm_public_ip" "nat_gateway" {
  name                = "nat-gateway-${random_integer.deployment.result}-pip"
  resource_group_name = data.terraform_remote_state.network.outputs.workload_rg_name
  location            = data.terraform_remote_state.network.outputs.workload_rg_location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "nat_gateway" {
  name                      = "nat-gateway-${random_integer.deployment.result}"
  location                  = data.terraform_remote_state.network.outputs.workload_rg_location
  resource_group_name       = data.terraform_remote_state.network.outputs.workload_rg_name
  sku_name                  = "Standard"
  idle_timeout_in_minutes   = 10
  #zones                    = ["1"]
}

resource "azurerm_nat_gateway_public_ip_association" "nat_gateway" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gateway.id
  public_ip_address_id = azurerm_public_ip.nat_gateway.id
}

resource "azurerm_subnet_nat_gateway_association" "devSubnet" {
  subnet_id      = azurerm_subnet.dev_subnet.id
  nat_gateway_id = azurerm_nat_gateway.nat_gateway.id
}

output "nat_gateway_id" {
  value = azurerm_nat_gateway.nat_gateway.id
}