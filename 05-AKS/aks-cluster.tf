locals {
  aks_clusters = {
    "aks_blue" = {
      name_prefix = "blue"
      aks_turn_on = true
      k8s_version = "1.27.3"
      appgw_name  = "appgw-blue"
    },
    "aks_green" = {
      name_prefix = "green"
      aks_turn_on = false
      k8s_version = "1.27.3"
      appgw_name  = "appgw-green"
    }
  }
}

module "aks" {
  source              = "./modules/aks"
  for_each            = { for aks_clusters in local.aks_clusters : aks_clusters.name_prefix => aks_clusters if aks_clusters.aks_turn_on == true }
  resource_group_name = data.terraform_remote_state.network.outputs.workload_rg_name
  location            = data.terraform_remote_state.network.outputs.workload_rg_location
  prefix              = "aks-${each.value.name_prefix}"
  vnet_subnet_id      = azurerm_subnet.aks.id
  mi_aks_cp_id        = azurerm_user_assigned_identity.mi_aks_cp[each.value.name_prefix].id
  la_id               = var.azurerm_log_analytics_workspace_id
  gateway_name        = "appgw-${each.value.name_prefix}"
  gateway_id          =  data.terraform_remote_state.support.outputs.gateway_id[each.value.appgw_name]   #module.appgw.outputs.gateway_id
  private_dns_zone_id = azurerm_private_dns_zone.aks_dns.id
  network_plugin      = try(var.network_plugin, "azure")
  pod_cidr            = try(var.pod_cidr, null)
  k8s_version         = each.value.k8s_version
  depends_on = [
    azurerm_role_assignment.aks_to_vnet,
    azurerm_role_assignment.aks_to_dnszone,
    azurerm_role_assignment.aks_to_nsg,
    azurerm_role_assignment.aks_to_storage,
    azurerm_role_assignment.aks_to_storage_nfs,
    azurerm_role_assignment.aks_to_rt,
    azurerm_subnet.aks
  ]
}

resource "azurerm_route_table" "rt" {
  count                         = var.network_plugin == "kubenet" ? 1 : 0
  name                          = "appgw-rt"
  location                      = data.terraform_remote_state.network.outputs.workload_rg_location
  resource_group_name           = data.terraform_remote_state.network.outputs.workload_rg_name
  disable_bgp_route_propagation = false
}

resource "azurerm_subnet_route_table_association" "rt_kubenet_association" {
  count          = var.network_plugin == "kubenet" ? 1 : 0
  subnet_id      = data.terraform_remote_state.support.outputs.appgw_subnet_id
  route_table_id = azurerm_route_table.rt[count.index].id
  depends_on = [ azurerm_route_table.rt]
}

resource "azurerm_key_vault_access_policy" "aks-aad_cp_identity-rt" {
  for_each     = azurerm_user_assigned_identity.mi_aks_cp
  key_vault_id = data.terraform_remote_state.support.outputs.key_vault_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = each.value.principal_id

  secret_permissions = [
    "Get", "List"
  ]
}