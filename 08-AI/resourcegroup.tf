# Resource Group for Landing Zone Networking
# This RG uses the same region location as the Hub.
resource "azurerm_resource_group" "ai_rg" {
  name     = "LZ-AI"
  location = var.ai_location
}

output "lz_rg_location" {
  value = azurerm_resource_group.ai_rg.location
}

output "lz_rg_name" {
  value = azurerm_resource_group.ai_rg.name
}