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
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.30"
    }
    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 1.4"
    }
  }
}

# We use credentials from the `onepassword` module to authenticate with cloud providers.
provider "onepassword" {
  service_account_token = var.onepassword_service_account_token
}

provider "digitalocean" {
  token = module.onepassword.credentials.digitalocean_access_token
}

provider "cloudflare" {
  api_token = module.onepassword.credentials.cloudflare_api_token
}


provider "kubernetes" {
  host                   = module.infra.kubernetes.host
  token                  = module.infra.kubernetes.token
  cluster_ca_certificate = module.infra.kubernetes.cluster_ca_certificate
}

provider "helm" {
  kubernetes {
    host                   = module.infra.kubernetes.host
    token                  = module.infra.kubernetes.token
    cluster_ca_certificate = module.infra.kubernetes.cluster_ca_certificate
  }
}

# The only credential passed in to tofu is a 1password service account token.
# Every other credential is stored in 1password and accessed via that token.
module "onepassword" {
  source = "./1password"
}

# Everything that sits below the application layer, e.g. VM's and databases,
# lives in the ./infra module.
module "infra" {
  source = "./infra"

  region                 = "nyc3"
  onepassword_vault_uuid = module.onepassword.vault_uuid

  kubernetes = {
    ha             = false
    version_prefix = "1.29"

    node = {
      size = "c-2"

      pool = {
        auto_scale = {
          from = 1
          to   = 3
        }
      }
    }

    maintenance_policy = {
      day        = "saturday"
      start_time = "08:00"
    }
  }

  postgres = {
    version          = 16
    storage_size_gib = 30

    nodes = {
      primary = {
        size = "db-s-1vcpu-2gb"
      }
    }

    maintenance_policy = {
      day        = "sunday"
      start_time = "08:00"
    }
  }
}

module "apps" {
  source = "./apps"

  onepassword = {
    service_account_token = var.onepassword_service_account_token
  }

  kubernetes = {
    namespace = "swag-lgbt-apps"
  }
}
