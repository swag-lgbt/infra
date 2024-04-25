terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.37"
    }
  }
}

resource "digitalocean_vpc" "swag_lgbt" {
  name   = "swag-lgbt-network"
  region = var.region
}

module "kubernetes" {
  source = "./kubernetes"

  region         = var.region
  vpc_uuid       = digitalocean_vpc.swag_lgbt.id
  version_prefix = var.kubernetes.version_prefix

  primary_cluster = {
    ha = var.kubernetes.primary_cluster.ha

    maintenance_policy = {
      day        = var.kubernetes.primary_cluster.maintenance_policy.day
      start_time = var.kubernetes.primary_cluster.maintenance_policy.start_time
    }

    node_pool = {
      min  = var.kubernetes.primary_cluster.node_pool.min
      max  = var.kubernetes.primary_cluster.node_pool.max
      size = var.kubernetes.primary_cluster.node_pool.size
    }
  }

  monitoring_cluster = {
    ha = var.kubernetes.monitoring_cluster.ha

    maintenance_policy = {
      day        = var.kubernetes.monitoring_cluster.maintenance_policy.day
      start_time = var.kubernetes.monitoring_cluster.maintenance_policy.start_time
    }

    node_pool = {
      min  = var.kubernetes.monitoring_cluster.node_pool.min
      max  = var.kubernetes.monitoring_cluster.node_pool.max
      size = var.kubernetes.monitoring_cluster.node_pool.size
    }
  }


}

module "postgres" {
  source = "./postgres"

  region   = var.region
  vpc_uuid = digitalocean_vpc.swag_lgbt.id

  standby_node_count = var.postgres.standby_node_count
  size               = var.postgres.size
  storage_size_mib   = var.postgres.capacity_gib * 1024

  pg_version = var.postgres.version

  firewall = {
    kubernetes_clusters = [
      module.kubernetes.primary_cluster,
      module.kubernetes.monitoring_cluster
    ]

    droplets = []
  }

  maintenance_policy = {
    day        = var.postgres.maintenance_policy.day
    start_time = var.postgres.maintenance_policy.start_time
  }
}

module "ssh_bridge" {
  source = "./ssh_bridge"

  region   = var.region
  vpc_uuid = digitalocean_vpc.swag_lgbt.id

  droplet = {
    name     = "swag-lgbt-access-bridge"
    size     = "s-1vcpu-1gb"
    ssh_keys = var.ssh_keys
  }
}
