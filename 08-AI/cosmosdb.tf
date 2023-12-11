resource "azurerm_cosmosdb_account" "cosmosdb_account" {
  name                          = "cosmosdb-${random_pet.funny_name.id}-${data.terraform_remote_state.aks-support.outputs.deployment_suffix}"
  location                      = azurerm_resource_group.ai_rg.location
  resource_group_name           = azurerm_resource_group.ai_rg.name
  offer_type                    = "Standard"
  kind                          = "GlobalDocumentDB"
  enable_automatic_failover     = false
  enable_free_tier              = false
  public_network_access_enabled = false
  network_acl_bypass_for_azure_services = true

  geo_location {
    location          = azurerm_resource_group.ai_rg.location
    failover_priority = 0
  }
  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }

}

resource "azurerm_cosmosdb_sql_database" "sql_database" {
  name                = "acgpt-cosmosdb-sqldb"
  resource_group_name = azurerm_resource_group.ai_rg.name
  account_name        = azurerm_cosmosdb_account.cosmosdb_account.name
  throughput          = 400
}

resource "azurerm_cosmosdb_sql_container" "sql_container" {
  name                  = "acgpt-sql-container"
  resource_group_name   = azurerm_resource_group.ai_rg.name
  account_name          = azurerm_cosmosdb_account.cosmosdb_account.name
  database_name         = azurerm_cosmosdb_sql_database.sql_database.name
  partition_key_path    = "/definition/id"
  partition_key_version = 1
  throughput            = 400

  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/*"
    }

    included_path {
      path = "/included/?"
    }

    excluded_path {
      path = "/excluded/?"
    }
  }

  unique_key {
    paths = ["/definition/idlong", "/definition/idshort"]
  }
}

# Deploy DNS Private Zone for cosmosdb

resource "azurerm_private_dns_zone" "cosmosdb_sql" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = azurerm_resource_group.ai_rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "lz_cosmosdb_sql" {
  name                  = "vnet_ai_link_to_cosmosdb"
  resource_group_name   = azurerm_resource_group.ai_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.cosmosdb_sql.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "hub_cosmosdb_sql" {
  name                  = "vnet_hub_link_to_cosmosdb"
  resource_group_name   = azurerm_resource_group.ai_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.cosmosdb_sql.name
  virtual_network_id    = data.terraform_remote_state.existing-hub.outputs.hub_vnet_id
}

# Cosmosdb Private Endpoint

resource "azurerm_private_endpoint" "cosmosdb_endpoint" {
  name                = "${azurerm_cosmosdb_account.cosmosdb_account.name}-ep"
  location            = azurerm_resource_group.ai_rg.location
  resource_group_name = azurerm_resource_group.ai_rg.name
  subnet_id           = azurerm_subnet.service_subnet.id

  private_service_connection {
    name                           = "${azurerm_cosmosdb_account.cosmosdb_account.name}-privateserviceconnection"
    private_connection_resource_id = azurerm_cosmosdb_account.cosmosdb_account.id
    subresource_names              = ["sql"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name = "cosmosdb-endpoint-zone"
    private_dns_zone_ids = [azurerm_private_dns_zone.cosmosdb_sql.id]
  }
}

