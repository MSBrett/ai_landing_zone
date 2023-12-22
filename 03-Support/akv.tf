module "create_kv" {
  source = "./modules/kv-private"

  name                     = "kv${random_integer.deployment.result}"
  resource_group_name      = data.terraform_remote_state.network.outputs.workload_rg_name
  location                 = data.terraform_remote_state.network.outputs.workload_rg_location
  tenant_id                = data.azurerm_client_config.current.tenant_id
  vnet_id                  = data.terraform_remote_state.network.outputs.workload_vnet_id
  dest_sub_id              = azurerm_subnet.service_subnet.id
  private_zone_id          = azurerm_private_dns_zone.kv-dns.id
  private_zone_name        = azurerm_private_dns_zone.kv-dns.name
  zone_resource_group_name = data.terraform_remote_state.network.outputs.workload_rg_name

}

resource "azurerm_private_dns_zone" "kv-dns" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = data.terraform_remote_state.network.outputs.workload_rg_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "workload_kv" {
  name                  = "vnet_workload_link_to_akv"
  resource_group_name   = data.terraform_remote_state.network.outputs.workload_rg_name
  private_dns_zone_name = azurerm_private_dns_zone.kv-dns.name
  virtual_network_id    = data.terraform_remote_state.network.outputs.workload_vnet_id
}

output "kv_private_zone_id" {
  value = azurerm_private_dns_zone.kv-dns.id
}

output "kv_private_zone_name" {
  value = azurerm_private_dns_zone.kv-dns.name
}

output "key_vault_id" {
  value = module.create_kv.kv_id
}