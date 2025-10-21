variable "resource_group_name" {
  default = "rg-aks-demo"
}

variable "location" {
  default = "eastus"
}

variable "aks_name" {
  default = "aks-demo-cluster"
}

variable "dns_prefix" {
  default = "aksdemo"
}

variable "node_count" {
  default = 2
}

variable "node_vm_size" {
  default = "Standard_D2s_v3"
}

variable "ssh_public_key_path" {
}

variable "tags" {
  default = {
    environment = "dev"
    project     = "Project_14_AKS_Cluster_with_Terraform"
  }
}
