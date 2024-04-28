
module "vpc" {
  source = "./vpc"

  region = var.region
  name   = "${var.project_name}-vpc"
}


module "kubernetes" {
  source = "./kubernetes"

  digitalocean = {
    region = var.region
    vpc    = module.vpc
  }

  cluster = {
    ha             = var.kubernetes.ha
    version_prefix = var.kubernetes.version_prefix
    name           = "${var.project_name}-k8s-main"

    maintenance_policy = var.kubernetes.maintenance_policy

    node = {
      # See available sizes by running `doctl compute size list`
      # "c-2"
      size = var.kubernetes.node.size

      pool = {
        name       = "${var.project_name}-node-pool"
        auto_scale = var.kubernetes.node.pool.auto_scale
        node_count = var.kubernetes.node.pool.node_count
      }
    }
  }
}

module "postgres" {
  source = "./postgres"

  onepassword = {
    vault_uuid = var.onepassword_vault_uuid

    admin_credentials = {
      title = "DigitalOcean Managed Postgres"
      tags  = ["DigitalOcean"]
    }
  }

  cluster = {
    name   = "${var.project_name}-postgres"
    region = var.region
    vpc    = module.vpc

    version            = var.postgres.version
    maintenance_policy = var.postgres.maintenance_policy
    storage_size_gib   = var.postgres.storage_size_gib
  }

  # See available sizes by running `doctl databases options slugs --engine pg`
  nodes = var.postgres.nodes

  firewall = {
    kubernetes_clusters = [module.kubernetes]
    droplets            = [module.tunnel.droplet]
  }
}

module "tunnel" {
  source = "./tunnel"

  onepassword = {
    vault_uuid = var.onepassword_vault_uuid
    tunnel_ssh_key = {
      title = "DigitalOcean Tunnel SSH Key"
    }
  }

  digitalocean = {
    region = var.region
    vpc    = module.vpc

    droplet = {
      image = "ubuntu-20-04-x64"
      name  = "${var.project_name}-ssh-tunnel"
      size  = "s-1vcpu-1gb"
    }
  }
}
