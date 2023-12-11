# Firewall Policy

variable "resource_group_name" {}
variable "location" {}
variable "onpremise_gateway_public_ip_address" {}
variable "firewall_public_ip_address" {}
variable "vm_private_ip_address" {}

resource "azurerm_firewall_policy" "hub" {
  name                = "vnet-hub-firewall-policy"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"
}

output "fw_policy_id" {
  value = azurerm_firewall_policy.hub.id
}

# Rules Collection Group

resource "azurerm_firewall_policy_rule_collection_group" "hub" {
  name               = "vnet-hub-rcg"
  firewall_policy_id = azurerm_firewall_policy.hub.id
  priority           = 200

  application_rule_collection {
    name     = "hub_app_rules"
    priority = 230
    action   = "Allow"
    rule {
      name = "aks_service"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses      = ["10.1.0.0/16"]
      destination_fqdn_tags = ["AzureKubnernetesService"]
    }
  }

  network_rule_collection {
    name     = "hub_network_rules"
    priority = 220
    action   = "Allow"
    rule {
      name                  = "https"
      protocols             = ["TCP"]
      source_addresses      = ["10.1.0.0/16"]
      destination_addresses = ["*"]
      destination_ports     = ["443"]
    }
    rule {
      name                  = "dns"
      protocols             = ["UDP"]
      source_addresses      = ["10.1.0.0/16"]
      destination_addresses = ["*"]
      destination_ports     = ["53"]
    }
    rule {
      name                  = "time"
      protocols             = ["UDP"]
      source_addresses      = ["10.1.0.0/16"]
      destination_addresses = ["*"]
      destination_ports     = ["123"]
    }
    rule {
      name                  = "tunnel_udp"
      protocols             = ["UDP"]
      source_addresses      = ["10.1.0.0/16"]
      destination_addresses = ["*"]
      destination_ports     = ["1194"]
    }
    rule {
      name                  = "tunnel_tcp"
      protocols             = ["TCP"]
      source_addresses      = ["10.1.0.0/16"]
      destination_addresses = ["*"]
      destination_ports     = ["9000"]
    }
    rule {
      name                  = "onprem_whitelist"
      protocols             = ["Any"]
      source_addresses      = ["192.168.1.0/24"]
      destination_addresses = ["*"]
      destination_ports     = ["*"]
    }
    rule {
      name                  = "bastion_vm_whitelist"
      protocols             = ["Any"]
      source_addresses      = [var.vm_private_ip_address]
      destination_addresses = ["*"]
      destination_ports     = ["*"]
    }
  }

  nat_rule_collection {
    name     = "hub_nat_rules"
    priority = 210
    action   = "Dnat"
    rule {
      name                = "ssh"
      protocols           = ["TCP"]
      source_addresses    = [var.onpremise_gateway_public_ip_address]
      destination_address = var.firewall_public_ip_address
      destination_ports   = ["22"]
      translated_address  = var.vm_private_ip_address
      translated_port     = "22"
    }
  }
}