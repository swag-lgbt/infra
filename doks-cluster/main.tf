terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.37"
    }
  }
}

data "digitalocean_kubernetes_versions" "current" {
  version_prefix = var.k8s_version
}

resource "digitalocean_kubernetes_cluster" "primary" {
  name   = var.cluster_name
  region = var.cluster_region

  version       = data.digitalocean_kubernetes_versions.current.latest_version
  auto_upgrade  = true
  surge_upgrade = true

  maintenance_policy {
    start_time = "04:00"
    day        = "sunday"
  }

  node_pool {
    name = "default"
    size = var.node_size_slug

    auto_scale = true
    max_nodes  = var.max_nodes
  }
}