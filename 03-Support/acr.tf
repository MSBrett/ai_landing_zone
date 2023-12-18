module "create_acr" {
  source = "./modules/acr-private"

  acrname             = "acr${random_integer.deployment.result}"
  resource_group_name = data.terraform_remote_state.network.outputs.workload_rg_name
  location            = data.terraform_remote_state.network.outputs.workload_rg_location
  aks_sub_id          = azurerm_subnet.service_subnet.id
  private_zone_id     = azurerm_private_dns_zone.acr-dns.id

}

resource "azurerm_private_dns_zone" "acr-dns" {
  name                = "privatelink.azurecr.io"
  resource_group_name = data.terraform_remote_state.network.outputs.workload_rg_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "workload_acr" {
  name                  = "vnet_workload_link_to_acr"
  resource_group_name   = data.terraform_remote_state.network.outputs.workload_rg_name
  private_dns_zone_name = azurerm_private_dns_zone.acr-dns.name
  virtual_network_id    = data.terraform_remote_state.network.outputs.workload_vnet_id
}

output "acr_private_zone_id" {
  value = azurerm_private_dns_zone.acr-dns.id
}

output "acr_private_zone_name" {
  value = azurerm_private_dns_zone.acr-dns.name
}

output "container_registry_id" {
  value = module.create_acr.acr_id
}