resource "azurerm_private_dns_zone_virtual_network_link" "workload_storage_account" {
  name                  = "vnet_workload_link_to_storage"
  resource_group_name   = data.terraform_remote_state.network.outputs.workload_rg_name
  private_dns_zone_name = azurerm_private_dns_zone.storage_account.name
  virtual_network_id    = data.terraform_remote_state.network.outputs.workload_vnet_id
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_zone_link_vnet" {
  name                  = "vnet_workload_link_to_apim"
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone.name
  resource_group_name   = data.terraform_remote_state.network.outputs.workload_rg_name
  virtual_network_id    = data.terraform_remote_state.network.outputs.workload_vnet_id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "workload_kv" {
  name                  = "vnet_workload_link_to_akv"
  resource_group_name   = data.terraform_remote_state.network.outputs.workload_rg_name
  private_dns_zone_name = azurerm_private_dns_zone.kv-dns.name
  virtual_network_id    = data.terraform_remote_state.network.outputs.workload_vnet_id
}

resource "azurerm_private_dns_zone_virtual_network_link" "workload_acr" {
  name                  = "vnet_workload_link_to_acr"
  resource_group_name   = data.terraform_remote_state.network.outputs.workload_rg_name
  private_dns_zone_name = azurerm_private_dns_zone.acr-dns.name
  virtual_network_id    = data.terraform_remote_state.network.outputs.workload_vnet_id
}

resource "azurerm_private_dns_zone_virtual_network_link" "workload_cosmosdb_sql" {
  name                  = "vnet_workload_link_to_cosmosdb"
  resource_group_name   = data.terraform_remote_state.network.outputs.workload_rg_name
  private_dns_zone_name = azurerm_private_dns_zone.cosmosdb_sql.name
  virtual_network_id    = data.terraform_remote_state.network.outputs.workload_vnet_id
}

resource "azurerm_private_dns_zone_virtual_network_link" "workload_openai" {
  name                  = "vnet_workload_link_to_openai"
  resource_group_name   = data.terraform_remote_state.network.outputs.workload_rg_name
  private_dns_zone_name = azurerm_private_dns_zone.openai-dns.name
  virtual_network_id    = data.terraform_remote_state.network.outputs.workload_vnet_id
}