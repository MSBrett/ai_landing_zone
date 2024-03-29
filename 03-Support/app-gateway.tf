# Application Gateway and Supporting Infrastructure

locals {
  appgws = {
    "appgw_blue" = {
      name_prefix   = "blue"
      appgw_turn_on = true
    },
    "appgw_green" = {
      name_prefix   = "green"
      appgw_turn_on = false
    }
  }
}

resource "azurerm_subnet" "appgw" {
  name                 = "appgwSubnet"
  resource_group_name  = data.terraform_remote_state.network.outputs.workload_rg_name
  virtual_network_name = data.terraform_remote_state.network.outputs.workload_vnet_name
  address_prefixes     = [data.terraform_remote_state.subnets.outputs.appgwSubnet]
  # private_endpoint_network_policies_enabled = false
}

module "appgw_nsgs" {
  source = "./modules/app_gw_nsg"

  resource_group_name = data.terraform_remote_state.network.outputs.workload_rg_name
  location            = data.terraform_remote_state.network.outputs.workload_rg_location
  nsg_name            = "${data.terraform_remote_state.network.outputs.workload_vnet_name}-${azurerm_subnet.appgw.name}-nsg"
}

resource "azurerm_subnet_network_security_group_association" "appgwsubnet" {
  subnet_id                 = azurerm_subnet.appgw.id
  network_security_group_id = module.appgw_nsgs.appgw_nsg_id
}

# based on the structure of the appgws map are deployed multiple appplication gateway, usually this is used in the blue green scenario
resource "azurerm_public_ip" "appgw" {
  for_each            = { for appgws in local.appgws : appgws.name_prefix => appgws if appgws.appgw_turn_on == true }
  name                = "appgw-pip-${each.value.name_prefix}"
  resource_group_name = data.terraform_remote_state.network.outputs.workload_rg_name
  location            = data.terraform_remote_state.network.outputs.workload_rg_location
  allocation_method   = "Static"
  sku                 = "Standard"
  ddos_protection_mode = "Enabled"
  ddos_protection_plan_id = data.terraform_remote_state.network.outputs.ddos_plan_id
}

# based on the structure of the appgws map are deployed multiple appplication gateway, usually this is used in the blue green scenario
module "appgw" {
  source = "./modules/app_gw"
  depends_on = [
    module.appgw_nsgs
  ]
  for_each             = { for appgws in local.appgws : appgws.name_prefix => appgws if appgws.appgw_turn_on == true }
  resource_group_name  = data.terraform_remote_state.network.outputs.workload_rg_name
  virtual_network_name = data.terraform_remote_state.network.outputs.workload_vnet_name
  location             = data.terraform_remote_state.network.outputs.workload_rg_location
  appgw_name           = "appgw-${each.value.name_prefix}"
  frontend_subnet      = azurerm_subnet.appgw.id
  appgw_pip            = azurerm_public_ip.appgw[each.value.name_prefix].id
}

# the app gateway name for each instance provisioned. If you are not using the blue green deployment then you can remove the for loop and use directly the attributes of the module module.appgw.
output "gateway_name" {
  value = { for appgws in module.appgw : appgws.gateway_name => appgws.gateway_name }
}

# the app gateway id for each instance provisioned. If you are not using the blue green deployment then you can remove the for loop and use directly the attributes of the module module.appgw.
output "gateway_id" {
  value = { for appgws in module.appgw : appgws.gateway_name => appgws.gateway_id }
}

# PIP IDs to permit the A Records registration in the DNS zone to invke the apps deployed on AKS. There is a PIP for each instance provisioned. If you are not using the blue green deployment then you can remove the for loop and use directly the attributes of the azurerm_public_ip.appgw resource.
output "azurerm_public_ip_ref" {
  value = { for pips in azurerm_public_ip.appgw : pips.name => pips.id }
}

output "appgw_subnet_id" {
  value = azurerm_subnet.appgw.id
}

output "appgw_subnet_name" {
  value = azurerm_subnet.appgw.name
}