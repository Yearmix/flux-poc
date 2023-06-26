terraform {}

provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "example" {
  name     = "k8s-test-app"  
}

resource "azurerm_public_ip" "example" {
  name                = "acceptance-test-public-ip1"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  allocation_method   = "Static"
  tags = azurerm_resource_group.example.tags
}

resource "azurerm_kubernetes_cluster" "example" {
  name                = "example-aks"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  dns_prefix          = "example-aks"
  node_resource_group = "${azurerm_resource_group.example.name}-nodes"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  load_balancer_profile {
    outbound_ip_address_ids = [ azurerm_public_ip.example.id ]
  }

  tags = azurerm_resource_group.example.tags
}

resource "azurerm_kubernetes_cluster_extension" "example" {
  name           = "example-ext"
  cluster_id     = azurerm_kubernetes_cluster.example.id
  extension_type = "microsoft.flux"
  depends_on = [ azurerm_kubernetes_cluster.example ]
}

resource "azurerm_kubernetes_flux_configuration" "example" {
  name       = "example-fc"
  cluster_id = azurerm_kubernetes_cluster.example.id
  namespace  = "flux"

  git_repository {
    url             = "https://github.com/Yearmix/git-ops"
    reference_type  = "branch"
    reference_value = "main"
    sync_interval_in_seconds = 60
    timeout_in_seconds = 60
  }

  # kustomizations {
  #   name = "infrastructure"
  #   path = "./infrastructure"
  #   retry_interval_in_seconds = 60
  #   timeout_in_seconds = 60
  #   sync_interval_in_seconds = 60
  #   recreating_enabled = true
  #   garbage_collection_enabled = true
  # }

  kustomizations {
    name = "apps"
    path = "./apps"
    retry_interval_in_seconds = 60
    timeout_in_seconds = 60
    sync_interval_in_seconds = 60
    recreating_enabled = true
    garbage_collection_enabled = true
#    depends_on = ["infrastructure"]
  }

  depends_on = [
    azurerm_kubernetes_cluster_extension.example
  ]
}