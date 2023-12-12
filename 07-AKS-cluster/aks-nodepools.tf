resource "azurerm_kubernetes_cluster_node_pool" "userpool" {
  for_each                = module.aks
  kubernetes_cluster_id   = each.value.aks_id
  name                    = "userpool"
  vm_size                 = "Standard_D8s_v4"
  node_count              = 2
  vnet_subnet_id          = data.terraform_remote_state.existing-lz.outputs.aks_subnet_id
}