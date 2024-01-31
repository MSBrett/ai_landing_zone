resource "azurerm_network_security_group" "postgresql_nsg" {
  name                = "workload-vnet-postgresqlSubnet-nsg"
  location            = data.terraform_remote_state.network.outputs.workload_rg_location
  resource_group_name = data.terraform_remote_state.network.outputs.workload_rg_name
}

resource "azurerm_subnet" "postgresq_subnet" {
  name                 = "postgresqlSubnet"
  virtual_network_name = data.terraform_remote_state.network.outputs.workload_vnet_name
  resource_group_name  = data.terraform_remote_state.network.outputs.workload_rg_name
  address_prefixes     = [data.terraform_remote_state.subnets.outputs.postgresqlSubnet]
  service_endpoints    = ["Microsoft.Storage"]

  delegation {
    name = "fs"

    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"

      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "postgresql_nsg" {
  subnet_id                 = azurerm_subnet.postgresq_subnet.id
  network_security_group_id = azurerm_network_security_group.postgresql_nsg.id
}

resource "azurerm_private_dns_zone" "postgresql_dns" {
  name                = "psql${random_integer.deployment.result}-pdz.postgres.database.azure.com"
  resource_group_name = data.terraform_remote_state.network.outputs.workload_rg_name

  depends_on = [azurerm_subnet_network_security_group_association.postgresql_nsg]
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgresql" {
  name                  = "psql${random_integer.deployment.result}-pdzvnetlink.com"
  private_dns_zone_name = azurerm_private_dns_zone.postgresql_dns.name
  virtual_network_id    = data.terraform_remote_state.network.outputs.workload_vnet_id
  resource_group_name   = data.terraform_remote_state.network.outputs.workload_rg_name
}

resource "azurerm_postgresql_flexible_server" "postgresql_flexible_server" {
  name                   = "psql${random_integer.deployment.result}"
  resource_group_name    = data.terraform_remote_state.network.outputs.workload_rg_name
  location               = data.terraform_remote_state.network.outputs.workload_rg_location
  version                = "13"
  delegated_subnet_id    = azurerm_subnet.postgresq_subnet.id
  private_dns_zone_id    = azurerm_private_dns_zone.postgresql_dns.id
  administrator_login    = var.admin_username
  administrator_password = var.admin_password
  zone                   = "1"
  storage_mb             = 32768
  sku_name               = "GP_Standard_D2s_v3"
  backup_retention_days  = 7

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgresql]
}

resource "azurerm_postgresql_flexible_server_database" "database" {
  name      = "db${random_integer.deployment.result}"
  server_id = azurerm_postgresql_flexible_server.postgresql_flexible_server.id
  collation = "en_US.utf8"
  charset   = "UTF8"
}