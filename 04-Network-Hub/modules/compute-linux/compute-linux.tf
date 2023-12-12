resource "azurerm_linux_virtual_machine" "compute" {
  
  name                            = var.server_name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = var.disable_password_authentication //Set to true if using SSH key
  tags                            = var.tags
  patch_assessment_mode           = "AutomaticByPlatform"
  patch_mode                      = "AutomaticByPlatform"
  bypass_platform_safety_checks_on_user_schedule_enabled = true

  network_interface_ids = [
    azurerm_network_interface.compute.id
  ]

  identity {
    type = "SystemAssigned"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.storage_account_type
  }

  source_image_reference {
    publisher = var.os_publisher
    offer     = var.os_offer
    sku       = var.os_sku
    version   = var.os_version

  }

  boot_diagnostics {
    storage_account_uri = null
  }
}

resource "azurerm_network_interface" "compute" {
  name                          = "${var.server_name}-nic"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  enable_accelerated_networking = var.enable_accelerated_networking

  tags = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.vnet_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

output "vm_private_ip_address" {
  value = azurerm_network_interface.compute.ip_configuration[0].private_ip_address
}