terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.85.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.12.1"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "helm" {
  kubernetes {
    config_path = "C:/Users/SZL/.kube/config"
  }
}

resource "azurerm_resource_group" "aks_rg" {
  name     = var.RG
  location = var.LOCATION
}