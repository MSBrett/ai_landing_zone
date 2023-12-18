# Deploy DNS Private Zone for AKS
resource "azurerm_private_dns_zone" "aks_dns" {
  name                = var.aks_private_dns_zone_name
  resource_group_name = data.terraform_remote_state.network.outputs.workload_rg_name
}

# Needed for Jumpbox to resolve cluster URL using a private endpoint and private dns zone
resource "azurerm_private_dns_zone_virtual_network_link" "workload_aks" {
  name                  = "vnet_workload_link_to_aks"
  resource_group_name   = data.terraform_remote_state.network.outputs.workload_rg_name
  private_dns_zone_name = azurerm_private_dns_zone.aks_dns.name
  virtual_network_id    = data.terraform_remote_state.network.outputs.workload_vnet_id
}

output "aks_private_zone_id" {
  value = azurerm_private_dns_zone.aks_dns.id
}
output "aks_private_zone_name" {
  value = azurerm_private_dns_zone.aks_dns.name
}