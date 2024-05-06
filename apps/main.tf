terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.29"
    }
  }
}

module "passport" {
  source = "./passport"

  cloudflare = {
    account_id   = var.cloudflare.account_id
    project_name = "swag-lgbt-passport"
    zone_id      = var.cloudflare.zone_id
  }

  passport = { subdomain = "account" }

  onepassword = { vault_uuid = var.onepassword.vault_uuid }
}

# module "secrets_injector" {
#   source = "./secrets_injector"

#   onepassword = var.onepassword
# }

# module "matrix" {
#   source = "./matrix"

#   secrets_injector = module.secrets_injector

#   onepassword_vault_uuid = var.onepassword.vault_uuid

#   matrix = {
#     data_volume_size_gib = 30
#     synapse_version      = "1.105.1"
#     default_room_version = 11
#   }

#   postgres = {
#     cluster_id           = var.postgres.cluster_id
#     connection_pool_size = 4
#   }
# }
