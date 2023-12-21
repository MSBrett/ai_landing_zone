
locals {
  HubAddressSpace=[cidrsubnet(var.workload_address_space, 8, 0)]
  SpokeAddressSpace=[cidrsubnet(var.workload_address_space, 3, 1)]
}

# HUB
output "HubAddressSpace" {
  value = local.HubAddressSpace[0]
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

output "AzureBastionSubnet" {
  value = cidrsubnet(local.SpokeAddressSpace[0], 7, 5)
}

output "GatewaySubnet" {
  value = cidrsubnet(local.SpokeAddressSpace[0], 7, 6)
}

output "AzureFirewallManagementSubnet" {
  value = cidrsubnet(local.SpokeAddressSpace[0], 7, 7)
}

output "AzureFirewallSubnet" {
  value = cidrsubnet(local.SpokeAddressSpace[0], 7, 8)
}

output "WorkloadAddressSpace" {
  value = local.SpokeAddressSpace[0]
}
