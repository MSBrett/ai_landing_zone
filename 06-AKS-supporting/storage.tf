
resource "random_string" "random" {
  length  = 8
  upper   = false
  special = false
}

resource "azurerm_storage_account" "storage_account" {
  name                     = "stor${random_string.random.id}"
  resource_group_name      = data.terraform_remote_state.existing-lz.outputs.lz_rg_name
  location                 = data.terraform_remote_state.existing-lz.outputs.lz_rg_location
  account_tier             = "Premium"
  account_replication_type = "LRS"
  account_kind             = "FileStorage"
  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    ip_rules                   = [var.onpremise_gateway_public_ip_address]
  }
}

resource "azurerm_storage_share" "share1" {
  name                 = "share1"
  storage_account_name = azurerm_storage_account.storage_account.name
  quota                = 1024
  enabled_protocol     = "NFS"
}

# Deploy DNS Private Zone for storage

resource "azurerm_private_dns_zone" "storage_account" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = data.terraform_remote_state.existing-lz.outputs.lz_rg_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "lz_storage_account" {
  name                  = "vnet_ai_link_to_storage"
  resource_group_name   = data.terraform_remote_state.existing-lz.outputs.lz_rg_name
  private_dns_zone_name = azurerm_private_dns_zone.storage_account.name
  virtual_network_id    = data.terraform_remote_state.existing-lz.outputs.lz_vnet_id
}

resource "azurerm_private_dns_zone_virtual_network_link" "hub_storage_account" {
  name                  = "vnet_hub_link_to_storage"
  resource_group_name   = data.terraform_remote_state.existing-lz.outputs.lz_rg_name
  private_dns_zone_name = azurerm_private_dns_zone.storage_account.name
  virtual_network_id    = data.terraform_remote_state.existing-hub.outputs.hub_vnet_id
}

# storage Private Endpoint

resource "azurerm_private_endpoint" "storage_endpoint" {
  name                = "storage-ep"
  location            = data.terraform_remote_state.existing-lz.outputs.lz_rg_location
  resource_group_name = data.terraform_remote_state.existing-lz.outputs.lz_rg_name
  subnet_id           = data.terraform_remote_state.existing-lz.outputs.aks_subnet_id

  private_service_connection {
    name                           = azurerm_storage_account.storage_account.name
    private_connection_resource_id = azurerm_storage_account.storage_account.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name = "storage-endpoint-zone"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage_account.id]
  }

  depends_on = [ azurerm_storage_share.share1 ]
}
