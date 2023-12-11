resource "random_pet" "funny_name" {
  length    = 2
  separator = "-"
}

resource "azurerm_public_ip" "apim" {
  name                = "apim-${random_pet.funny_name.id}-${data.terraform_remote_state.aks-support.outputs.deployment_suffix}-pip"
  location            = azurerm_resource_group.ai_rg.location
  resource_group_name = azurerm_resource_group.ai_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "apim-${random_pet.funny_name.id}-${data.terraform_remote_state.aks-support.outputs.deployment_suffix}"
}

resource "azurerm_api_management" "apim" {
  name                = "apim-${random_pet.funny_name.id}-${data.terraform_remote_state.aks-support.outputs.deployment_suffix}"
  location            = azurerm_resource_group.ai_rg.location
  resource_group_name = azurerm_resource_group.ai_rg.name
  publisher_name      = "Microsoft"
  publisher_email     = "info@microsoft.com"
  public_ip_address_id = azurerm_public_ip.apim.id

  sku_name = "Developer_1"
  #sku_name = "Consumption_0"
  
  virtual_network_type = "Internal"

  virtual_network_configuration {
    subnet_id = azurerm_subnet.apim.id
  }

  identity {
    type = "SystemAssigned"
  }

  policy {
    xml_content = <<XML
    <policies>
      <inbound />
      <backend />
      <outbound />
      <on-error />
    </policies>
  XML
  }

  timeouts {
    create = "1h"
    update = "1h"
    delete = "1h"
  }
}

# Identity
resource "azurerm_role_assignment" "apim_to_openai" {
  principal_id          = azurerm_api_management.apim.identity[0].principal_id
  role_definition_name  = "Cognitive Services OpenAI User"
  scope                 = azurerm_cognitive_account.openai_account.id
}

# Create DNS Zone and register it with the VNET
resource "azurerm_private_dns_zone" "private_dns_zone" {
  name                = "azure-api.net"
  resource_group_name = azurerm_resource_group.ai_rg.name
}

resource "azurerm_private_dns_a_record" "private_dns_a_record" {
  name                = "apim-${data.terraform_remote_state.aks-support.outputs.deployment_suffix}"
  zone_name           = azurerm_private_dns_zone.private_dns_zone.name
  resource_group_name = azurerm_resource_group.ai_rg.name
  ttl                 = 300
  records             = [azurerm_api_management.apim.private_ip_addresses[0]]
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_zone_link_vnet" {
  name                  = "dns-link-vnet-ai"
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone.name
  resource_group_name   = azurerm_resource_group.ai_rg.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_zone_link_hub" {
  name                  = "dns-link-vnet-hub"
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone.name
  resource_group_name   = azurerm_resource_group.ai_rg.name
  virtual_network_id    = data.terraform_remote_state.existing-hub.outputs.hub_vnet_id
  registration_enabled  = false
}



