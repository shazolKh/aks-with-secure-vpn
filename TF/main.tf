locals {
  vnet_name            = "Terraform-ELK-VNet"
  aks_public_ip_name   = "Terraform-ELK-Public-IP"
  p2s_gw_name          = "Terraform-ELK-VNet-GW"
  p2s_gw_ipconfig_name = "Vnet-GW-IP-Config"
  root_cert_name       = "root"
  PUBLIC_CERT_DATA     = file("rootcert.txt")
  dns_prefix           = "terraform-elk-cluster-dns"
  cluster_name         = "Terraform-ELK-Cluster"
  vm_size              = "Standard_DS2_v2"
  orchestrator_version = "1.27.7"
}

resource "azurerm_virtual_network" "aks_vnet" {
  name                = local.vnet_name
  location            = var.LOCATION
  resource_group_name = var.RG
  address_space       = ["10.0.0.0/16"]

  depends_on = [azurerm_resource_group.aks_rg]
}

resource "azurerm_subnet" "aks_default_subnet" {
  name                 = "default"
  resource_group_name  = var.RG
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  depends_on = [azurerm_virtual_network.aks_vnet]
}

resource "azurerm_subnet" "gateway_subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = var.RG
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = ["10.0.2.0/24"]

  depends_on = [azurerm_virtual_network.aks_vnet]
}

resource "azurerm_public_ip" "aks_public_ip" {
  name                = local.aks_public_ip_name
  location            = var.LOCATION
  resource_group_name = var.RG
  allocation_method   = "Dynamic"

  depends_on = [azurerm_resource_group.aks_rg]
}

resource "azurerm_virtual_network_gateway" "aks_p2s_gw" {
  name                = local.p2s_gw_name
  location            = var.LOCATION
  resource_group_name = var.RG
  type                = "Vpn"
  vpn_type            = "RouteBased"

  sku           = "VpnGw1"
  active_active = false
  enable_bgp    = false

  ip_configuration {
    name                 = local.p2s_gw_ipconfig_name
    public_ip_address_id = azurerm_public_ip.aks_public_ip.id
    subnet_id            = azurerm_subnet.gateway_subnet.id
  }

  vpn_client_configuration {
    address_space        = ["192.168.0.0/24"]
    vpn_client_protocols = ["SSTP"]

    root_certificate {
      name             = local.root_cert_name
      public_cert_data = local.PUBLIC_CERT_DATA
    }
  }

  depends_on = [azurerm_subnet.gateway_subnet, azurerm_public_ip.aks_public_ip, azurerm_kubernetes_cluster.aks_cluster]
}

# output "aks_vnet_subnet_output" {
#   value = azurerm_virtual_network.aks_vnet.subnet
# }

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  location                            = var.LOCATION
  name                                = local.cluster_name
  resource_group_name                 = var.RG
  azure_policy_enabled                = false
  dns_prefix                          = local.dns_prefix
  kubernetes_version                  = "1.27.7"
  open_service_mesh_enabled           = false
  private_cluster_enabled             = true
  private_cluster_public_fqdn_enabled = true

  default_node_pool {
    enable_auto_scaling          = true
    enable_host_encryption       = false
    enable_node_public_ip        = false
    kubelet_disk_type            = "OS"
    max_count                    = 5
    min_count                    = 1
    max_pods                     = 110
    node_count                   = 1
    name                         = "agentpool"
    only_critical_addons_enabled = false
    orchestrator_version         = "1.27.7"
    os_disk_size_gb              = 128
    vm_size                      = local.vm_size
    vnet_subnet_id               = azurerm_subnet.aks_default_subnet.id
  }

  network_profile {
    dns_service_ip = "10.1.0.10"
    network_plugin = "kubenet"
    network_policy = "calico"
    # pod_cidr       = "10.244.0.0/16"
    service_cidr = "10.1.0.0/16"
  }
  identity {
    type = "SystemAssigned"
  }
  storage_profile {
    snapshot_controller_enabled = false
  }
  depends_on = [azurerm_subnet.aks_default_subnet]
}

resource "azurerm_kubernetes_cluster_node_pool" "aks_node_pool" {
  enable_auto_scaling    = true
  enable_host_encryption = false
  enable_node_public_ip  = false
  eviction_policy        = "Deallocate"
  fips_enabled           = false
  kubernetes_cluster_id  = azurerm_kubernetes_cluster.aks_cluster.id
  max_count              = 10
  min_count              = 1
  mode                   = "User"
  name                   = "spotnodepool"
  node_count             = 1
  orchestrator_version   = local.orchestrator_version
  os_disk_size_gb        = 128
  os_sku                 = "Ubuntu"
  priority               = "Spot"
  vm_size                = "Standard_D2s_v3"
  vnet_subnet_id         = azurerm_subnet.aks_default_subnet.id

  depends_on = [ azurerm_resource_group.aks_rg, azurerm_kubernetes_cluster.aks_cluster, azurerm_virtual_network.aks_vnet ]
}