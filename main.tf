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
  host                   = module.credentials.kubernetes.host
  token                  = module.credentials.kubernetes.token
  cluster_ca_certificate = module.credentials.kubernetes.cluster_ca_certificate
}

provider "helm" {
  kubernetes {
    host                   = module.credentials.kubernetes.host
    token                  = module.credentials.kubernetes.token
    cluster_ca_certificate = module.credentials.kubernetes.cluster_ca_certificate
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
    cluster = {
      name = module.subcluster.kubernetes.cluster.name
    }
  }

  postgres = {
    name = module.subcluster.postgres.name
  }
}

module "subcluster" {
  source = "./subcluster"

  region = "nyc3"

  kubernetes = {
    cluster = {
      version_prefix = "1.29"
    }

    node_pool = {
      min_nodes = 1
      max_nodes = 3
      size      = "c-2"
    }

    maintenance_policy = {
      start_time = "04:00"
      day        = "friday"
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
