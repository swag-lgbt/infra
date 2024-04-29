terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.29"
    }
  }
}

resource "kubernetes_namespace" "apps" {
  metadata {
    name = "swag-lgbt-apps"
  }
}

locals {
  kubernetes_namespace = kubernetes_namespace.apps.metadata[0].name
}

module "secrets_injector" {
  source = "./secrets_injector"

  onepassword = var.onepassword
  kubernetes  = { namespace = local.kubernetes_namespace }
}

module "matrix" {
  source = "./matrix"

  secrets_injector = module.secrets_injector

  onepassword_vault_uuid = var.onepassword.vault_uuid

  matrix = {
    data_volume_size_gib = 30
    synapse_version      = "1.105.1"
    default_room_version = 11
  }

  postgres = {
    cluster_id           = var.postgres.cluster_id
    connection_pool_size = 4
  }

  kubernetes = {
    namespace = local.kubernetes_namespace
  }
}
