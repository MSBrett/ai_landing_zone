resource "azurerm_cognitive_account" "cognitive_service" {
  name                = "cognitive-services-${data.terraform_remote_state.aks-support.outputs.deployment_suffix}"
  location            = azurerm_resource_group.ai_rg.location
  resource_group_name = azurerm_resource_group.ai_rg.name
  sku_name            = var.cognitive_services_sku
  kind                = "CognitiveServices"
}

resource "azurerm_cognitive_account" "openai_account" {
  name                = "openai-${random_pet.funny_name.id}-${data.terraform_remote_state.aks-support.outputs.deployment_suffix}"
  location            = azurerm_resource_group.ai_rg.location
  resource_group_name = azurerm_resource_group.ai_rg.name
  kind                = "OpenAI"
  sku_name            = var.aoai_sku
  custom_subdomain_name              = "openai-${random_pet.funny_name.id}-${data.terraform_remote_state.aks-support.outputs.deployment_suffix}"
  dynamic_throttling_enabled         = false
  fqdns                              = []
  local_auth_enabled                 = true
  outbound_network_access_restricted = false
  public_network_access_enabled      = true
  tags                = var.tags

  identity {
    type = "SystemAssigned"
  }
}


/*
resource "azurerm_cognitive_deployment" "openai_deployment" {
  name                 =  "${locals.account_name}-001"
  cognitive_account_id = azurerm_cognitive_account.openai_account.id
  model {
    format  = "OpenAI"
    name    = "text-curie-001"
    version = "1"
  }

  scale {
    type = "Standard"
  }
}
*/

# Deploy DNS Private Zone for OpenAI

resource "azurerm_private_dns_zone" "openai-dns" {
  name                = "privatelink.openai.azure.com"
  resource_group_name = azurerm_resource_group.ai_rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "lz_openai" {
  name                  = "vnet_ai_link_to_openai"
  resource_group_name   = azurerm_resource_group.ai_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.openai-dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "hub_openai" {
  name                  = "vnet_hub_link_to_openai"
  resource_group_name   = azurerm_resource_group.ai_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.openai-dns.name
  virtual_network_id    = data.terraform_remote_state.existing-hub.outputs.hub_vnet_id
}

# OpenAI Private Endpoint

resource "azurerm_private_endpoint" "openai-endpoint" {
  name                = "openai-${random_pet.funny_name.id}-${data.terraform_remote_state.aks-support.outputs.deployment_suffix}-ep"
  location            = azurerm_resource_group.ai_rg.location
  resource_group_name = azurerm_resource_group.ai_rg.name
  subnet_id           = azurerm_subnet.service_subnet.id

  private_service_connection {
    name                           = "openai-${random_pet.funny_name.id}-${data.terraform_remote_state.aks-support.outputs.deployment_suffix}-privateserviceconnection"
    private_connection_resource_id = azurerm_cognitive_account.openai_account.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name = "openai-endpoint-zone"
    private_dns_zone_ids = [azurerm_private_dns_zone.openai-dns.id]
  }
}

# Outputs

output "openai_private_zone_id" {
  value = azurerm_private_dns_zone.openai-dns.id
}

output "openai_private_zone_name" {
  value = azurerm_private_dns_zone.openai-dns.name
}

output "openai_account_id" {
  value = azurerm_cognitive_account.openai_account.id
}

output "openai_account_name" {
  value = azurerm_cognitive_account.openai_account.name
}

output "azurerm_cognitive_account_name" {
  value = azurerm_cognitive_account.cognitive_service.name
}

output "azurerm_cognitive_account_id" {
  value = azurerm_cognitive_account.cognitive_service.id
}

resource "azurerm_search_service" "search" {
  name                = "cognitive-search-${data.terraform_remote_state.aks-support.outputs.deployment_suffix}"
  location            = azurerm_resource_group.ai_rg.location
  resource_group_name = azurerm_resource_group.ai_rg.name
  sku                 = var.search_sku
  replica_count       = var.search_replica_count
  partition_count     = var.search_partition_count
}

output "search_service_name" {
  value = azurerm_search_service.search.name
}

output "search_service_id" {
  value = azurerm_search_service.search.id
}