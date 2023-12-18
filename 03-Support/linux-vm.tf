####################################
# These resources will create an addtional subnet for user connectivity
# and a Linux Server to use with the Bastion Service.
####################################

# Dev Subnet
# (Additional subnet for Developer Jumpbox)
resource "azurerm_subnet" "dev_subnet" {
  name                                      = "devSubnet"
  resource_group_name                       = data.terraform_remote_state.network.outputs.workload_rg_name
  virtual_network_name                      = data.terraform_remote_state.network.outputs.workload_vnet_name
  address_prefixes                          = [data.terraform_remote_state.subnets.outputs.devSubnet]
  private_endpoint_network_policies_enabled = false
}

resource "azurerm_network_security_group" "dev-nsg" {
  name                = "${data.terraform_remote_state.network.outputs.workload_vnet_name}-${azurerm_subnet.dev_subnet.name}-nsg"
  resource_group_name = data.terraform_remote_state.network.outputs.workload_rg_name
  location            = data.terraform_remote_state.network.outputs.workload_rg_location
}

resource "azurerm_subnet_network_security_group_association" "subnet" {
  subnet_id                 = azurerm_subnet.dev_subnet.id
  network_security_group_id = azurerm_network_security_group.dev-nsg.id
}

# Linux Server VM

resource "azurerm_linux_virtual_machine" "compute" {
  
  name                            = var.server_name
  location                        = data.terraform_remote_state.network.outputs.workload_rg_location
  resource_group_name             = data.terraform_remote_state.network.outputs.workload_rg_name
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
  location                      = data.terraform_remote_state.network.outputs.workload_rg_location
  resource_group_name           = data.terraform_remote_state.network.outputs.workload_rg_name
  enable_accelerated_networking = var.enable_accelerated_networking

  tags = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.dev_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "vm_shutdown_schedule" {
  virtual_machine_id = azurerm_linux_virtual_machine.compute.id
  location           = data.terraform_remote_state.network.outputs.workload_rg_location
  enabled            = true

  daily_recurrence_time = "2000"
  timezone              = "Pacific Standard Time"


  notification_settings {
    enabled         = false
   
  }
 }

output "vm_private_ip_address" {
  value = azurerm_network_interface.compute.ip_configuration[0].private_ip_address
}

#######################
# VARIABLES #
#######################

variable "admin_username" {
  sensitive = true
  default = "sysadmin"
}

variable "admin_password" {
  sensitive = true
  default = "changeme"
}

variable "server_name" {
  default = "linuxvm"
}

variable "os_publisher" {
  default = "canonical"
}

variable "os_offer" {
  default = "0001-com-ubuntu-server-focal"
}

variable "os_sku" {
  default = "20_04-lts-gen2"
}

variable "os_version" {
  default = "latest"
}

variable "disable_password_authentication" {
  default = false #leave as true if using ssh key, if using a password make the value false
}

variable "enable_accelerated_networking" {
  default = "false"
}

variable "storage_account_type" {
  default = "Standard_LRS"
}

variable "vm_size" {
  default = "Standard_D2s_v4"
}

variable "tags" {
  type = map(string)

  default = {
    application = "compute"
  }
}

variable "allocation_method" {
  default = "Static"
}
