resource "azurerm_user_assigned_identity" "mi_aks_cp" {
  for_each            = { for aks_clusters in local.aks_clusters : aks_clusters.name_prefix => aks_clusters if aks_clusters.aks_turn_on == true }
  name                = "mi-aks-${each.value.name_prefix}-cp"
  resource_group_name = data.terraform_remote_state.network.outputs.workload_rg_name
  location            = data.terraform_remote_state.network.outputs.workload_rg_location
}

# Role Assignments for Control Plane MSI
# Based on the structure of the aks_clusters map is defined the role assignment per each AKS Cluster, this is mainly used in the blue green deployment scenario.
resource "azurerm_role_assignment" "aks_to_vnet" {
  for_each             = azurerm_user_assigned_identity.mi_aks_cp
  scope                = data.terraform_remote_state.network.outputs.workload_vnet_id
  role_definition_name = "Network Contributor"
  principal_id         = each.value.principal_id
}

resource "azurerm_role_assignment" "aks_to_nsg" {
  for_each             = azurerm_user_assigned_identity.mi_aks_cp
  scope                = azurerm_network_security_group.aks_nsg.id
  role_definition_name = "Contributor"
  principal_id         = each.value.principal_id
}

resource "azurerm_role_assignment" "aks_to_storage" {
  for_each             = azurerm_user_assigned_identity.mi_aks_cp
  scope                = data.terraform_remote_state.support.outputs.storage_account_id
  role_definition_name = "Contributor"
  principal_id         = each.value.principal_id
}

resource "azurerm_role_assignment" "aks_to_storage_nfs" {
  for_each             = azurerm_user_assigned_identity.mi_aks_cp
  scope                = data.terraform_remote_state.support.outputs.storage_account_id
  role_definition_name = "Storage File Data Privileged Contributor"
  principal_id         = each.value.principal_id
}

# Role assignment to to create Private DNS zone for cluster
# Based on the structure of the aks_clusters map is defined the role assignment per each AKS Cluster, this is mainly used in the blue green deployment scenario.
resource "azurerm_role_assignment" "aks_to_dnszone" {
  for_each             = azurerm_user_assigned_identity.mi_aks_cp
  scope                = azurerm_private_dns_zone.aks_dns.id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = each.value.principal_id
}


# The AKS cluster. 
# Based on the instances of AKS Clusters deployed are defined the role assignments per each cluster, this is mainly used in the blue green deployment scenario.
resource "azurerm_role_assignment" "appdevs_user" {
  for_each             = module.aks
  scope                = each.value.aks_id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = data.terraform_remote_state.aad.outputs.appdev_object_id
}

resource "azurerm_role_assignment" "aksops_admin" {
  for_each             = module.aks
  scope                = each.value.aks_id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = data.terraform_remote_state.aad.outputs.aksops_object_id
}

# This role assigned grants the current user running the deployment admin rights
# to the cluster. In production, you should use just the AAD groups (above).
# Based on the instances of AKS Clusters deployed are defined the role assignments per each cluster, this is mainly used in the blue green deployment scenario.
resource "azurerm_role_assignment" "aks_rbac_admin" {
  for_each             = module.aks
  scope                = each.value.aks_id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = data.azurerm_client_config.current.object_id

}

# Role Assignment to Azure Container Registry from AKS Cluster
# This must be granted after the cluster is created in order to use the kubelet identity.
# Based on the instances of AKS Clusters deployed are defined the role assignments per each cluster, this is mainly used in the blue green deployment scenario.

resource "azurerm_role_assignment" "aks_to_acr" {
  for_each             = module.aks
  scope                = data.terraform_remote_state.support.outputs.container_registry_id
  role_definition_name = "AcrPull"
  principal_id         = each.value.kubelet_id
}

# Role Assignments for AGIC on AppGW
# This must be granted after the cluster is created in order to use the ingress identity.
# Based on the instances of AKS Clusters deployed are defined the role assignments per each cluster, this is mainly used in the blue green deployment scenario.

resource "azurerm_role_assignment" "agic_appgw" {
  for_each             = module.aks
  scope                = each.value.appgw_id
  role_definition_name = "Contributor"
  principal_id         = each.value.agic_id
}

# These resources will set up the required permissions for 
# AAD Pod Identity (v1)


# Managed Identity for Pod Identity
resource "azurerm_user_assigned_identity" "aks_pod_identity" {
  resource_group_name = data.terraform_remote_state.network.outputs.workload_rg_name
  location            = data.terraform_remote_state.network.outputs.workload_rg_location
  name                = "mi-aks-pod"
}


# Role assignments
# Based on the instances of AKS Clusters deployed are defined the role assignments per each cluster, this is mainly used in the blue green deployment scenario.
resource "azurerm_role_assignment" "aks_identity_operator" {
  for_each             = module.aks
  scope                = azurerm_user_assigned_identity.aks_pod_identity.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = each.value.kubelet_id
}

resource "azurerm_role_assignment" "aks_vm_contributor" {
  for_each             = module.aks
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourcegroups/${each.value.node_pool_rg}"
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = each.value.kubelet_id

  lifecycle {
    ignore_changes = [ scope ]
  }
}

# Azure Key Vault Access Policy for Managed Identity for AAD Pod Identity
resource "azurerm_key_vault_access_policy" "aad_pod_identity" {
  key_vault_id = data.terraform_remote_state.support.outputs.key_vault_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.aks_pod_identity.principal_id

  secret_permissions = [
    "Get", "List"
  ]
}

# Outputs
output "aad_pod_identity_resource_id" {
  value       = azurerm_user_assigned_identity.aks_pod_identity.id
  description = "Resource ID for the Managed Identity for AAD Pod Identity"
}

output "aad_pod_identity_client_id" {
  value       = azurerm_user_assigned_identity.aks_pod_identity.client_id
  description = "Client ID for the Managed Identity for AAD Pod Identity"
}