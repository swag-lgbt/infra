terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.37"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.29"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 1.4"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.30"
    }
  }
}

# PROVIDERS

provider "onepassword" {
  service_account_token = var.onepassword_service_account_token
}

provider "digitalocean" {
  token = module.credentials.digitalocean.token
}

provider "cloudflare" {
  api_token = module.credentials.cloudflare.api_token
}

provider "kubernetes" {
  host                   = module.credentials.kubernetes.primary_cluster.host
  token                  = module.credentials.kubernetes.primary_cluster.token
  cluster_ca_certificate = module.credentials.kubernetes.primary_cluster.cluster_ca_certificate
}

provider "helm" {
  kubernetes {
    host                   = module.credentials.kubernetes.primary_cluster.host
    token                  = module.credentials.kubernetes.primary_cluster.token
    cluster_ca_certificate = module.credentials.kubernetes.primary_cluster.cluster_ca_certificate
  }
}

provider "kubernetes" {
  alias = "monitoring"

  host                   = module.credentials.kubernetes.monitoring_cluster.host
  token                  = module.credentials.kubernetes.monitoring_cluster.token
  cluster_ca_certificate = module.credentials.kubernetes.monitoring_cluster.cluster_ca_certificate
}

provider "helm" {
  alias = "monitoring"

  kubernetes {
    host                   = module.credentials.kubernetes.monitoring_cluster.host
    token                  = module.credentials.kubernetes.monitoring_cluster.token
    cluster_ca_certificate = module.credentials.kubernetes.monitoring_cluster.cluster_ca_certificate
  }
}

# Modules
#
# NOTICE: modules should be named in snake_case, not kebab-case
# on account of this issue: https://github.com/helm/helm/issues/9731

module "credentials" {
  source = "./credentials"

  onepassword = {
    service_account_token = var.onepassword_service_account_token
  }

  kubernetes = {
    primary_cluster = {
      name = module.subcluster.kubernetes.primary_cluster.name
    }

    monitoring_cluster = {
      name = module.subcluster.kubernetes.monitoring_cluster.name
    }
  }

  postgres = {
    name = module.subcluster.postgres.name
  }
}

module "subcluster" {
  source = "./subcluster"

  region = "nyc3"
  # TODO: once we can synchronize ssh keys between DO, OP, and TF, we should...just waiting on OP...
  ssh_keys = ["9d:98:09:73:06:15:0c:09:d9:63:fd:72:1e:e2:4a:8f"]

  kubernetes = {
    version_prefix = "1.29"
    primary_cluster = {
      ha = false

      node_pool = {
        min  = 1
        max  = 3
        size = "c-2"
      }

      maintenance_policy = {
        start_time = "04:00"
        day        = "friday"
      }
    }

    monitoring_cluster = {
      ha = false


      node_pool = {
        min  = 1
        max  = 3
        size = "c-2"
      }

      maintenance_policy = {
        start_time = "04:00"
        day        = "friday"
      }
    }


  }

  postgres = {
    capacity_gib       = 30
    standby_node_count = 1
    size               = "db-s-1vcpu-2gb"
    version            = 16

    maintenance_policy = {
      start_time = "04:00"
      day        = "saturday"
    }
  }
}

module "intracluster" {
  source = "./intracluster"

  onepassword = {
    service_account_token = var.onepassword_service_account_token
  }
}
