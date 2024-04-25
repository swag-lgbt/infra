terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.37"
    }
  }
}

data "digitalocean_kubernetes_versions" "swag_lgbt" {
  version_prefix = var.version_prefix
}

resource "digitalocean_kubernetes_cluster" "primary" {
  name     = "primary-kubernetes-cluster"
  region   = var.region
  vpc_uuid = var.vpc_uuid

  version       = data.digitalocean_kubernetes_versions.swag_lgbt.latest_version
  auto_upgrade  = true
  surge_upgrade = true
  ha            = var.primary_cluster.ha

  maintenance_policy {
    start_time = var.primary_cluster.maintenance_policy.start_time
    day        = var.primary_cluster.maintenance_policy.day
  }

  node_pool {
    name = "primary-cluster-default-node-pool"
    size = var.primary_cluster.node_pool.size

    auto_scale = true
    min_nodes  = var.primary_cluster.node_pool.min
    max_nodes  = var.primary_cluster.node_pool.max
  }
}

resource "digitalocean_kubernetes_cluster" "monitoring" {
  name     = "monitoring-kubernetes-cluster"
  region   = var.region
  vpc_uuid = var.vpc_uuid

  version       = data.digitalocean_kubernetes_versions.swag_lgbt.latest_version
  auto_upgrade  = true
  surge_upgrade = true
  ha            = var.monitoring_cluster.ha

  maintenance_policy {
    start_time = var.monitoring_cluster.maintenance_policy.start_time
    day        = var.monitoring_cluster.maintenance_policy.day
  }

  node_pool {
    name = "monitoring-cluster-default-node-pool"
    size = var.monitoring_cluster.node_pool.size

    auto_scale = true
    min_nodes  = var.monitoring_cluster.node_pool.min
    max_nodes  = var.monitoring_cluster.node_pool.max
  }
}
