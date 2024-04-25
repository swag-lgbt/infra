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

  cluster = {
    region         = var.region
    version_prefix = var.kubernetes.cluster.version_prefix
    vpc_uuid       = digitalocean_vpc.swag_lgbt.id
  }

  maintenance_policy = {
    day        = var.kubernetes.maintenance_policy.day
    start_time = var.kubernetes.maintenance_policy.start_time
  }

  node_pool = {
    min_nodes = var.kubernetes.node_pool.min_nodes
    max_nodes = var.kubernetes.node_pool.max_nodes
    size      = var.kubernetes.node_pool.size
  }
}

module "postgres" {
  source = "./postgres"

  region   = var.region
  vpc_uuid = digitalocean_vpc.swag_lgbt.id

  standby_node_count = var.postgres.standby_node_count
  size               = var.postgres.size
  storage_size_mib   = var.postgres.capacity_gib * 1024

  pg_version            = var.postgres.version
  kubernetes_cluster_id = module.kubernetes.cluster.id

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
