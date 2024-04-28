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

# do some cleanup since there's no optional chaining
locals {
  node_pool_auto_scale = var.cluster.node.pool.auto_scale == null ? false : true
  node_pool_min_nodes  = local.node_pool_auto_scale ? var.cluster.node.pool.auto_scale.from : null
  node_pool_max_nodes  = local.node_pool_auto_scale ? var.cluster.node.pool.auto_scale.to : null
}

resource "digitalocean_kubernetes_cluster" "main" {
  name     = var.cluster.name
  region   = var.digitalocean.region
  vpc_uuid = var.digitalocean.vpc.id

  version       = data.digitalocean_kubernetes_versions.swag_lgbt.latest_version
  auto_upgrade  = true
  surge_upgrade = true
  ha            = var.cluster.ha

  maintenance_policy {
    start_time = var.cluster.maintenance_policy.start_time
    day        = var.cluster.maintenance_policy.day
  }

  node_pool {
    name = var.cluster.node.pool.name
    size = var.cluster.node.size

    auto_scale = local.node_pool_auto_scale
    min_nodes  = local.node_pool_min_nodes
    max_nodes  = local.node_pool_max_nodes

    node_count = var.cluster.node.pool.node_count
  }
}
