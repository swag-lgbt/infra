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
# 1password is configured via the OP_SERVICE_ACCOUNT_TOKEN environment variable

provider "cloudflare" {
  api_token = module.data.onepassword.credentials.cloudflare_api_token
}


# provider "kubernetes" {
#   host                   = module.infra.kubernetes.host
#   token                  = module.infra.kubernetes.token
#   cluster_ca_certificate = module.infra.kubernetes.cluster_ca_certificate
# }

# provider "helm" {
#   kubernetes {
#     host                   = module.infra.kubernetes.host
#     token                  = module.infra.kubernetes.token
#     cluster_ca_certificate = module.infra.kubernetes.cluster_ca_certificate
#   }
# }

# MODULES
#
# In general, apps should own their own tofu. THose all live in /apps.
# Other modules are for things that aren't explicitly owned by a single app.

# The "data" module owns tofu-specific data that isn't tied to a particular project,
# for example a Cloudflare Zone ID
module "data" {
  source = "./tofu"
}

# The "infra" module owns infrastructure that isn't tied to a particular project,
# for example a kubernetes cluster
# module "infra" {
#   source = "./infra"

#   region                 = "nyc3"
#   onepassword_vault_uuid = module.data.onepassword.vault_uuid

#   kubernetes = {
#     ha             = false
#     version_prefix = "1.29"

#     node = {
#       size = "c-2"

#       pool = {
#         auto_scale = {
#           from = 1
#           to   = 3
#         }
#       }
#     }

#     maintenance_policy = {
#       day        = "saturday"
#       start_time = "08:00"
#     }
#   }

#   postgres = {
#     version          = 16
#     storage_size_gib = 30

#     nodes = {
#       primary = {
#         size = "db-s-1vcpu-2gb"
#       }
#     }

#     maintenance_policy = {
#       day        = "sunday"
#       start_time = "08:00"
#     }
#   }
# }

# The "apps" module contains all swagLGBT related applications, which all own their own tofu.
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
