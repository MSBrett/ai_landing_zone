
locals {
  HubAddressSpace=[cidrsubnet(var.workload_address_space, 8, 0)]
  SpokeAddressSpace=[cidrsubnet(var.workload_address_space, 3, 1)]
}

# HUB
output "HubAddressSpace" {
  value = local.HubAddressSpace[0]
}

output "GatewaySubnet" {
  value = cidrsubnet(local.HubAddressSpace[0], 2, 0)
}

output "AzureBastionSubnet" {
  value = cidrsubnet(local.HubAddressSpace[0], 2, 1)
}

output "AzureFirewallManagementSubnet" {
  value = cidrsubnet(local.HubAddressSpace[0], 2, 2)
}

output "AzureFirewallSubnet" {
  value = cidrsubnet(local.HubAddressSpace[0], 2, 3)
}

# WORKLOAD
output "aksSubnet" {
  value = cidrsubnet(local.SpokeAddressSpace[0], 1, 1)
}

output "apimSubnet" {
  value = cidrsubnet(local.SpokeAddressSpace[0], 7, 1)
}

output "devSubnet" {
  value = cidrsubnet(local.SpokeAddressSpace[0], 7, 3)
}

output "postgresqlSubnet" {
  value = cidrsubnet(local.SpokeAddressSpace[0], 7, 2)
}

output "serviceSubnet" {
  value = cidrsubnet(local.SpokeAddressSpace[0], 7, 0)
}

output "appgwSubnet" {
  value = cidrsubnet(local.SpokeAddressSpace[0], 7, 4)
}

output "WorkloadAddressSpace" {
  value = local.SpokeAddressSpace[0]
}
