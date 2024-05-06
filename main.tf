terraform {
  required_version = "~> 1.7.0"

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
  }

  backend "s3" {
    bucket = "tfstate"
    # https://developers.cloudflare.com/r2/api/s3/api/#bucket-region
    region = "auto"
    key    = "swag-lgbt"

    skip_credentials_validation = true
    skip_region_validation      = true
    skip_s3_checksum            = true
  }
}

# PROVIDER CONFIGURATION
#
# Note: 1password is configured via the OP_SERVICE_ACCOUNT_TOKEN environment variable,
# so there's no configuration here in the file.

provider "digitalocean" {
  token = module.data.onepassword.credentials.digitalocean_access_token
}

provider "cloudflare" {
  api_token = module.data.onepassword.credentials.cloudflare_api_token
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

# Extra tofu data that isn't tied to a particular project
module "data" {
  source = "./tofu"
}

# Everything that sits below the application layer, e.g. VM's and databases,
# lives in the ./infra module.
module "infra" {
  source = "./infra"

  region                 = "nyc3"
  onepassword_vault_uuid = module.data.onepassword.vault_uuid

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
    service_account_token = module.data.onepassword.credentials.onepassword_service_account_token
    vault_uuid            = module.data.onepassword.vault_uuid
  }

  # postgres = {
  #   cluster_id = module.infra.postgres.id
  # }

  cloudflare = {
    account_id = module.data.cloudflare.account_id
    zone_id    = module.data.cloudflare.zone_id
  }
}
