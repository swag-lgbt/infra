terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.37"
    }
  }
}

resource "digitalocean_database_cluster" "postgres" {
  name = "swag-lgbt-postgres-cluster"

  region               = var.region
  private_network_uuid = var.vpc_uuid

  engine  = "pg"
  version = var.pg_version


  size       = var.size
  node_count = var.standby_node_count + 1

  maintenance_window {
    day  = var.maintenance_policy.day
    hour = var.maintenance_policy.start_time
  }
}

# Funnily enough, the cluster is actually usually open by default to the public internet ??
# So we have to create a firewall rule to only allow traffic from our kubernetes cluster
resource "digitalocean_database_firewall" "postgres_firewall" {
  cluster_id = digitalocean_database_cluster.postgres.id

  dynamic "rule" {
    for_each = var.firewall.kubernetes_clusters

    content {
      type  = "k8s"
      value = rule.value.id
    }
  }

  dynamic "rule" {
    for_each = var.firewall.droplets

    content {
      type  = "droplet"
      value = rule.value.id
    }
  }
}
