output "kube_config" {
   value     = azurerm_kubernetes_cluster.aks.kube_admin_config_raw
  sensitive = true
}

output "resource_group_name" {
  value = azurerm_kubernetes_cluster.aks.resource_group_name
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}
