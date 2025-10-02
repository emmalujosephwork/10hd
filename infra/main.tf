terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.114"
    }
  }
}

provider "azurerm" {
  features {}
}

# ---------------------
# Variables
# ---------------------
variable "location" {
  description = "Azure region to deploy resources in"
  type        = string
  default     = "australiaeast"
}

variable "resource_group" {
  description = "Name of the resource group"
  type        = string
}

variable "acr_name" {
  description = "Name of the Azure Container Registry (must be globally unique)"
  type        = string
}

variable "aks_name" {
  description = "Name of the AKS cluster"
  type        = string
}

# ---------------------
# Resources
# ---------------------

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group
  location = var.location
}

# Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "sit722"

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name       = "sys"
    node_count = 1
    vm_size    = "Standard_B2s"
  }

  role_based_access_control_enabled = true
}

# Allow AKS to pull from ACR
resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

# ---------------------
# Outputs
# ---------------------
output "rg" {
  description = "Resource Group name"
  value       = azurerm_resource_group.rg.name
}

output "acr_login" {
  description = "ACR login server"
  value       = azurerm_container_registry.acr.login_server
}

output "acr_admin_user" {
  description = "ACR admin username"
  value       = azurerm_container_registry.acr.admin_username
}

output "aks" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.aks.name
}
