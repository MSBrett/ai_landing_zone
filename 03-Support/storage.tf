resource "azurerm_storage_account" "storage_account" {
  name                            = "storage${lower(var.deployment_prefix)}${random_integer.deployment.result}"
  resource_group_name             = data.terraform_remote_state.network.outputs.workload_rg_name
  location                        = data.terraform_remote_state.network.outputs.workload_rg_location
  account_tier                    = "Premium"
  account_replication_type        = "LRS"
  account_kind                    = "FileStorage"
  allow_nested_items_to_be_public = false
  enable_https_traffic_only       = false
  

  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    ip_rules                   = [var.onpremise_gateway_public_ip_address]
  }

  lifecycle {
    ignore_changes = [
      network_rules[0].private_link_access
    ]
  }
}

output "storage_account_id" {
  value = azurerm_storage_account.storage_account.id
}

resource "azurerm_storage_share" "share1" {
  name                 = "data"
  storage_account_name = azurerm_storage_account.storage_account.name
  quota                = 1024
  enabled_protocol     = "NFS"
}

# Deploy DNS Private Zone for storage

resource "azurerm_private_dns_zone" "storage_account" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = data.terraform_remote_state.network.outputs.workload_rg_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "workload_storage_account" {
  name                  = "vnet_workload_link_to_storage"
  resource_group_name   = data.terraform_remote_state.network.outputs.workload_rg_name
  private_dns_zone_name = azurerm_private_dns_zone.storage_account.name
  virtual_network_id    = data.terraform_remote_state.network.outputs.workload_vnet_id
}

# storage Private Endpoint

resource "azurerm_private_endpoint" "storage_endpoint" {
  name                = "storage-ep"
  location            = data.terraform_remote_state.network.outputs.workload_rg_location
  resource_group_name = data.terraform_remote_state.network.outputs.workload_rg_name
  subnet_id           = azurerm_subnet.service_subnet.id

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
