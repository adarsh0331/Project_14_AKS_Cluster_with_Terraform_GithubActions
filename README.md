# AKS Cluster Deployment with Terraform  
**Production-Ready, Secure, and Fully Automated**

[![Azure](https://img.shields.io/badge/Azure-0078D4?style=for-the-badge&logo=microsoft-azure&logoColor=white)](https://azure.microsoft.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)

---

## Overview

This repository provides **Infrastructure as Code (IaC)** to deploy a **production-grade Azure Kubernetes Service (AKS)** cluster using **Terraform**.  

It follows **Azure best practices** for:
- Secure networking
- Identity & access control
- Scalability
- Observability
- GitOps readiness

---

## Objective

> **Provision a secure, scalable, and observable AKS cluster on Azure using Terraform — with zero manual steps.**

---

## Tools & Technologies

| Category               | Tools Used |
|------------------------|------------|
| **Cloud Provider**     | Microsoft Azure |
| **Orchestration**      | Azure Kubernetes Service (AKS) |
| **IaC**                | HashiCorp Terraform (`>= 1.5`) |
| **Identity**           | System-assigned Managed Identity, Azure RBAC |
| **Networking**         | VNet, Subnets, NSG, Azure CNI |
| **Container Registry** | Azure Container Registry (ACR) |
| **State Management**   | Azure Blob Storage (remote backend) |
| **CLI**                | `az`, `kubectl`, `terraform` |

---

## Project Structure

```bash
terraform-aks/
├── main.tf                 # Root module orchestration
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── terraform.tfvars        # Default variable values
├── backend.tf              # Remote state configuration
├── versions.tf             # Provider & Terraform version constraints
├── modules/
│   ├── network/            # VNet, Subnets, NSG
│   ├── aks/                # AKS cluster + node pools
│   ├── acr/                # Azure Container Registry
│   └── role-assignments/   # RBAC bindings
└── README.md               # You're here!
```

---

## Prerequisites

| Tool | Version | Install |
|------|--------|-------|
| Terraform | `>= 1.5` | [Download](https://www.terraform.io/downloads.html) |
| Azure CLI | Latest | `curl -sL https://aka.ms/InstallAzureCLIDeb \| sudo bash` |
| kubectl | Latest | `az aks install-cli` |

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "your-subscription-id"
```

---

## Step-by-Step Implementation

---

### 1. Configure Remote Backend (`backend.tf`)

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstateprod"
    container_name       = "tfstate"
    key                  = "prod.aks.cluster.tfstate"
  }
}
```

> **Create storage account first** (one-time):
```bash
az group create --name tfstate-rg --location eastus
az storage account create \
  --name tfstateprod \
  --resource-group tfstate-rg \
  --location eastus \
  --sku Standard_LRS \
  --encryption-services blob
az storage container create \
  --name tfstate \
  --account-name tfstateprod
```

---

### 2. Provider Configuration (`versions.tf`)

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {}
}
```

---

### 3. Input Variables (`variables.tf`)

```hcl
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "aks-prod-rg"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "cluster_name" {
  description = "AKS cluster name"
  type        = string
  default     = "prod-aks-cluster"
}

variable "acr_name" {
  description = "ACR name (globally unique)"
  type        = string
}
```

---

### 4. `terraform.tfvars` (Example)

```hcl
resource_group_name = "aks-prod-rg"
location            = "eastus"
cluster_name        = "prod-aks-01"
acr_name            = "mycompanyacrprod2025"  # Must be globally unique
```

---

### 5. Networking Module (`modules/network/main.tf`)

```hcl
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
}
```

---

### 6. AKS Cluster Module (`modules/aks/main.tf`)

```hcl
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix

  default_node_pool {
    name                = "default"
    node_count          = 3
    vm_size             = "Standard_DS2_v2"
    vnet_subnet_id      = var.subnet_id
    enable_auto_scaling = true
    min_count           = 2
    max_count           = 5
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
  }

  azure_active_directory_role_based_access_control {
    managed = true
    admin_group_object_ids = var.aad_admin_group_ids
  }

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

---

### 7. ACR Module (`modules/acr/main.tf`)

```hcl
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Premium"
  admin_enabled       = false
  georeplications {
    location = "West US"
  }
}

# Allow AKS to pull images
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = var.aks_identity_principal_id
}
```

---

### 8. Root Module (`main.tf`)

```hcl
module "network" {
  source              = "./modules/network"
  resource_group_name = var.resource_group_name
  location            = var.location
  prefix              = var.cluster_name
}

module "aks" {
  source              = "./modules/aks"
  cluster_name        = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = lower(var.cluster_name)
  subnet_id           = module.network.aks_subnet_id
  aad_admin_group_ids = ["your-aad-group-object-id"]
}

module "acr" {
  source                  = "./modules/acr"
  acr_name                = var.acr_name
  resource_group_name     = var.resource_group_name
  location                = var.location
  aks_identity_principal_id = module.aks.system_assigned_identity
}
```

---

### 9. Outputs (`outputs.tf`)

```hcl
output "aks_cluster_name" {
  value = module.aks.cluster_name
}

output "kube_config" {
  value     = module.aks.kube_config_raw
  sensitive = true
}

output "acr_login_server" {
  value = module.acr.acr_login_server
}

output "resource_group_name" {
  value = var.resource_group_name
}
```

---

## Deploy the Cluster

```bash
# 1. Initialize Terraform
terraform init

# 2. Review plan
terraform plan -out=tfplan

# 3. Apply
terraform apply tfplan
```

> **Duration**: ~10–15 minutes

---

## Access the Cluster

```bash
# Get kubeconfig
terraform output -raw kube_config > ~/.kube/aks-prod-config

# Set context
export KUBECONFIG=~/.kube/aks-prod-config

# Verify
kubectl get nodes
```

---

## Expected Outcome

| Resource | Status |
|--------|--------|
| AKS Cluster | Running, 3+ nodes |
| VNet + Subnet | Isolated, secure |
| ACR | Premium tier, geo-replicated |
| RBAC | Azure AD integrated |
| IAM | Least privilege via managed identity |

---

## Best Practices Implemented

| Practice | Implementation |
|--------|----------------|
| **Modular Design** | Reusable `network`, `aks`, `acr` modules |
| **Remote State** | Locked & versioned in Azure Blob |
| **System-Assigned Identity** | No secrets in code |
| **Azure CNI + Standard LB** | Better networking & performance |
| **Auto-scaling Node Pool** | Cost & resilience |
| **AAD RBAC** | Enterprise-grade access control |
| **Geo-replicated ACR** | High availability |
| **Tagging** | Cost allocation & governance |

---

## Security Features

- **No admin credentials** — uses Azure AD
- **Network isolation** via dedicated subnet
- **NSG rules** (customize in `network` module)
- **Private endpoint support** (add to ACR)
- **Secret management** via Azure Key Vault (optional)

---

## CI/CD Integration (GitHub Actions)

```yaml
# .github/workflows/terraform.yml
name: Terraform AKS Deploy

on:
  push:
    branches: [ main ]

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2

      - name: Terraform Init
        run: terraform init

      - name: Terraform Apply
        run: terraform apply -auto-approve
        env:
          ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
          ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
          ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
```

---

## Cleanup (Destroy)

```bash
terraform destroy
```

> **Warning**: This deletes all resources.

---

## Troubleshooting

| Issue | Solution |
|------|---------|
| `az login` expired | Run `az login` again |
| `kubectl` not working | Re-export `KUBECONFIG` |
| ACR pull fails | Verify `AcrPull` role assignment |
| Nodes not ready | Check subnet NSG rules |

---

## Next Steps

| Feature | How to Add |
|-------|-----------|
| **Private AKS Cluster** | Set `private_cluster_enabled = true` |
| **Ingress Controller** | Deploy NGINX via Helm |
| **Monitoring** | Enable Azure Monitor for containers |
| **ArgoCD / Flux** | Bootstrap GitOps |
| **Key Vault CSI Driver** | Store app secrets |


---

**Production-Ready AKS | 100% IaC | Secure by Default**

*Last Updated: November 04, 2025*  
*License: MIT*  

---
