terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.37"
    }
  }
}

data "digitalocean_kubernetes_versions" "swag_lgbt" {
  version_prefix = var.cluster.version_prefix
}

resource "digitalocean_kubernetes_cluster" "swag_lgbt" {
  name     = "swag-lgbt-kubernetes-cluster"
  region   = var.cluster.region
  vpc_uuid = var.cluster.vpc_uuid

  version       = data.digitalocean_kubernetes_versions.swag_lgbt.latest_version
  auto_upgrade  = true
  surge_upgrade = true

  maintenance_policy {
    start_time = var.maintenance_policy.start_time
    day        = var.maintenance_policy.day
  }

  node_pool {
    name = "swag-lgbt-default-node-pool"
    size = var.node_pool.size

    auto_scale = true
    min_nodes  = var.node_pool.min_nodes
    max_nodes  = var.node_pool.max_nodes
  }
}
