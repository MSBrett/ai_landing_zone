resource "azurerm_network_security_group" "postgresq_subnet" {
  name                = "postgresql-${random_string.random.id}-nsg"
  location            = data.terraform_remote_state.existing-lz.outputs.lz_rg_location
  resource_group_name = data.terraform_remote_state.existing-lz.outputs.lz_rg_name
}

resource "azurerm_subnet" "postgresq_subnet" {
  name                 = "postgresq-subnet"
  virtual_network_name = data.terraform_remote_state.existing-lz.outputs.lz_vnet_name
  resource_group_name  = data.terraform_remote_state.existing-lz.outputs.lz_rg_name
  address_prefixes     = ["10.1.2.0/24"]
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
  network_security_group_id = azurerm_network_security_group.postgresq_subnet.id
}

resource "azurerm_private_dns_zone" "postgresql_dns" {
  name                = "postgresql-${random_string.random.id}-pdz.postgres.database.azure.com"
  resource_group_name = data.terraform_remote_state.existing-lz.outputs.lz_rg_name

  depends_on = [azurerm_subnet_network_security_group_association.postgresql_nsg]
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgresql" {
  name                  = "postgresql-${random_string.random.id}-pdzvnetlink.com"
  private_dns_zone_name = azurerm_private_dns_zone.postgresql_dns.name
  virtual_network_id    = data.terraform_remote_state.existing-lz.outputs.lz_vnet_id
  resource_group_name   = data.terraform_remote_state.existing-lz.outputs.lz_rg_name
}

resource "azurerm_postgresql_flexible_server" "default" {
  name                   = "postgresql-${random_string.random.id}"
  resource_group_name    = data.terraform_remote_state.existing-lz.outputs.lz_rg_name
  location               = data.terraform_remote_state.existing-lz.outputs.lz_rg_location
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