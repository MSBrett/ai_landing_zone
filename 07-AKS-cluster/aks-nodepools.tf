resource "azurerm_kubernetes_cluster_node_pool" "userpool" {
  for_each                = module.aks
  kubernetes_cluster_id   = each.value.aks_id
  name                    = "userpool"
  vm_size                 = var.userpool_vm_size
  node_count              = 1
  vnet_subnet_id          = data.terraform_remote_state.existing-lz.outputs.aks_subnet_id
}

#resource "azurerm_kubernetes_cluster_node_pool" "usergpupool" {
#  for_each                = module.aks
#  kubernetes_cluster_id   = each.value.aks_id
#  name                    = "usergpupool"
#  vm_size                 = var.usergpupool_vm_size
#  node_count              = 1
#  vnet_subnet_id          = data.terraform_remote_state.existing-lz.outputs.aks_subnet_id
#}