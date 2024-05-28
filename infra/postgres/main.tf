terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.37"
    }
    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 2.0"
    }
  }
}

resource "digitalocean_database_cluster" "postgres" {
  name = var.cluster.name

  region               = var.cluster.region
  private_network_uuid = var.cluster.vpc.id

  engine  = "pg"
  version = var.cluster.version


  size       = var.nodes.primary.size
  node_count = var.nodes.failover.count + 1

  maintenance_window {
    day  = var.cluster.maintenance_policy.day
    hour = var.cluster.maintenance_policy.start_time
  }

  storage_size_mib = var.cluster.storage_size_gib * 1024
}

# Funnily enough, the cluster is actually usually open by default to the public internet ??
resource "digitalocean_database_firewall" "postgres" {

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

  dynamic "rule" {
    for_each = var.firewall.ip_addrs

    content {
      type  = "ip_addr"
      value = rule.value
    }
  }

  dynamic "rule" {
    for_each = var.firewall.tags

    content {
      type  = "tag"
      value = rule.value
    }
  }

  dynamic "rule" {
    for_each = var.firewall.apps

    content {
      type  = "app"
      value = rule.value.id
    }
  }
}

# Persist the admin credentials to 1password so we can log in later if necessary
resource "onepassword_item" "postgres_admin_credentials" {
  vault = var.onepassword.vault_uuid

  title = var.onepassword.admin_credentials.title

  category = "database"
  type     = "postgresql"

  database = resource.digitalocean_database_cluster.postgres.database
  hostname = resource.digitalocean_database_cluster.postgres.host
  port     = resource.digitalocean_database_cluster.postgres.port

  username = resource.digitalocean_database_cluster.postgres.user
  password = resource.digitalocean_database_cluster.postgres.password

  tags = var.onepassword.admin_credentials.tags
}
